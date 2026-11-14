import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

final notificationProvider =
    ChangeNotifierProvider<NotificationProvider>((ref) {
  return NotificationProvider();
});

class NotificationProvider extends ChangeNotifier {
  static const String _dismissedCacheKey = 'grocery_dismissed_notifications';
  static const String _readCacheKey = 'grocery_read_notifications';

  final FirestoreService _firestoreService = FirestoreService();

  List<NotificationModel> _broadcastList = [];
  List<NotificationModel> _personalList = [];
  List<NotificationModel> _mergedNotifications = [];

  final Set<String> _dismissedIds = {};
  final Set<String> _readIds = {};

  StreamSubscription<List<NotificationModel>>? _broadcastSub;
  StreamSubscription<List<NotificationModel>>? _personalSub;
  StreamSubscription<User?>? _authSub;

  String? _currentUserId;
  bool _isLoading = true;

  NotificationProvider() {
    _initialize();
  }

  List<NotificationModel> get notifications => _mergedNotifications;
  bool get isLoading => _isLoading;
  int get unreadCount {
    return _mergedNotifications.where((n) {
      if (_readIds.contains(n.id)) return false;
      return !n.isRead;
    }).length;
  }

  Future<void> _initialize() async {
    await _loadLocalPreferences();

    // Listen to broadcast notifications
    _broadcastSub = _firestoreService.streamBroadcastNotifications().listen(
      (list) {
        _broadcastList = list;
        _recomputeMergedList();
      },
      onError: (err) {
        debugPrint('Broadcast notifications stream error: $err');
      },
    );

    // Listen to Auth State to stream user personal notifications
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUid = user?.uid;
      if (newUid != _currentUserId) {
        _currentUserId = newUid;
        _subscribeToPersonalNotifications();
      }
    });

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _subscribeToPersonalNotifications();
  }

  void _subscribeToPersonalNotifications() {
    _personalSub?.cancel();
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _personalList = [];
      _recomputeMergedList();
      return;
    }

    _personalSub = _firestoreService
        .streamUserNotifications(_currentUserId!)
        .listen(
          (list) {
            _personalList = list;
            _recomputeMergedList();
          },
          onError: (err) {
            debugPrint('Personal notifications stream error: $err');
          },
        );
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedList = prefs.getStringList(_dismissedCacheKey) ?? [];
      final readList = prefs.getStringList(_readCacheKey) ?? [];
      _dismissedIds.addAll(dismissedList);
      _readIds.addAll(readList);
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  void _recomputeMergedList() {
    final Map<String, NotificationModel> map = {};

    // 1. Add Personal Notifications
    for (final n in _personalList) {
      if (!_dismissedIds.contains(n.id)) {
        map[n.id] = n;
      }
    }

    // 2. Add Broadcast Notifications (If duplicate id, personal takes precedence)
    for (final n in _broadcastList) {
      if (!_dismissedIds.contains(n.id) && !map.containsKey(n.id)) {
        map[n.id] = n;
      }
    }

    final combined = map.values.toList();
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _mergedNotifications = combined;
    _isLoading = false;
    notifyListeners();
  }

  /// Dismiss / Swipe to delete a single notification
  Future<void> dismiss(NotificationModel item) async {
    _dismissedIds.add(item.id);

    // Remove from in-memory list immediately for instantaneous 60fps swipe animation
    _mergedNotifications.removeWhere((n) => n.id == item.id);
    notifyListeners();

    // Persist dismissed IDs locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissedCacheKey, _dismissedIds.toList());
    } catch (_) {}

    // If personal notification, also delete from Firestore doc
    if (item.isPersonal && _currentUserId != null && _currentUserId!.isNotEmpty) {
      await _firestoreService.deleteUserNotification(_currentUserId!, item.id);
    }
  }

  /// Clear all notifications (Swipe or Clear All button)
  Future<void> clearAll() async {
    for (final item in _mergedNotifications) {
      _dismissedIds.add(item.id);
    }
    _mergedNotifications.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissedCacheKey, _dismissedIds.toList());
    } catch (_) {}

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await _firestoreService.clearAllUserNotifications(_currentUserId!);
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(NotificationModel item) async {
    if (_readIds.contains(item.id)) return;
    _readIds.add(item.id);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readCacheKey, _readIds.toList());
    } catch (_) {}

    if (item.isPersonal && _currentUserId != null && _currentUserId!.isNotEmpty) {
      await _firestoreService.markUserNotificationAsRead(
        _currentUserId!,
        item.id,
      );
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    for (final item in _mergedNotifications) {
      _readIds.add(item.id);
      if (item.isPersonal && _currentUserId != null && _currentUserId!.isNotEmpty) {
        _firestoreService.markUserNotificationAsRead(_currentUserId!, item.id);
      }
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readCacheKey, _readIds.toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    _personalSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

