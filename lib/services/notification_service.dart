import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../routes/app_routes.dart';

/// Top-level background message handler required by FirebaseMessaging.
/// Must be annotated with `@pragma('vm:entry-point')` so it can be called
/// when the app is in the background or completely terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint(
    'FCM Background message received: ${message.messageId}, data: ${message.data}',
  );
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'groceryhub_high_importance',
    'GroceryHub Orders & Alerts',
    description:
        'High importance notifications for GroceryHub orders, delivery tracking, and flash deals.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initializes Local Notifications, Firebase Messaging permissions,
  /// notification channels, and sets up listeners for:
  /// 1. Foreground messages (`FirebaseMessaging.onMessage`)
  /// 2. Background tap events (`FirebaseMessaging.onMessageOpenedApp`)
  /// 3. Killed / Terminated state launch (`FirebaseMessaging.instance.getInitialMessage`)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Android & iOS Initialization Settings (Do not prompt on startup/splash)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // Initialize FlutterLocalNotificationsPlugin with tap handler
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      // 2. Create High-Importance Android Notification Channel
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
      }

      // 3. Configure Foreground Presentation Options
      try {
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // 4. Setup Token Acquisition (non-blocking) and Listen for Refresh
      _retrieveAndSyncToken().catchError((e) {
        debugPrint('FCM Token retrieval error: $e');
      });

      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        await syncTokenWithFirestore(newToken);
      });

      // 6. State 1: FOREGROUND MESSAGE LISTENER
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.messageId}');
        _showForegroundLocalNotification(message);
      });

      // 7. State 2: BACKGROUND MESSAGE TAP LISTENER
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped from background state: ${message.data}');
        _handleNotificationNavigation(message.data);
      });

      // 8. State 3: KILLED / TERMINATED STATE COLD START CHECK
      _fcm.getInitialMessage().then((initialMessage) {
        if (initialMessage != null) {
          debugPrint(
            'FCM Notification launched app from terminated/killed state: ${initialMessage.data}',
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            _handleNotificationNavigation(initialMessage.data);
          });
        }
      }).catchError((e) {
        debugPrint('Error checking initialMessage: $e');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  /// Displays a heads-up local banner notification when a push is received while in foreground.
  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'GroceryHub Alert';
    final body = notification?.body ?? message.data['body'] ?? '';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFF7C415),
      playSound: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Handles user tapping on a local notification banner
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Navigates the user to the relevant screen based on payload data.
  /// Works across Foreground, Background, and Terminated states without BuildContext issues.
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    final targetRoute = data['route'] ?? data['screen'] ?? data['click_action'];
    final navState = AppRoutes.navigatorKey.currentState;

    if (navState == null) {
      debugPrint('NavigatorState not available for notification routing.');
      return;
    }

    if (targetRoute != null && targetRoute.toString().isNotEmpty) {
      final routeStr = targetRoute.toString().trim();
      try {
        if (routeStr == '/orders' ||
            data['type'] == 'order_status') {
          navState.pushNamed(AppRoutes.home);
        } else if (routeStr == AppRoutes.chat || routeStr == '/chat') {
          navState.pushNamed(AppRoutes.chat);
        } else if (routeStr == AppRoutes.complaints ||
            routeStr == '/complaints') {
          navState.pushNamed(AppRoutes.complaints);
        } else if (routeStr == AppRoutes.catalog || routeStr == '/catalog') {
          navState.pushNamed(
            AppRoutes.catalog,
            arguments: {
              'title': data['catalogTitle'] ?? 'Offers & Specials',
              'sectionType': data['sectionType'] ?? 'deals',
            },
          );
        } else if (routeStr == AppRoutes.wishlist || routeStr == '/wishlist') {
          navState.pushNamed(AppRoutes.wishlist);
        } else {
          navState.pushNamed(routeStr);
        }
      } catch (e) {
        debugPrint('Failed to navigate to route $routeStr: $e');
      }
    }
  }

  /// Explicitly requests notification permissions for Android 13+ (POST_NOTIFICATIONS) and iOS.
  /// Should be called after the user lands on the Home screen to avoid intrusive early popups.
  Future<void> requestNotificationPermission() async {
    try {
      // 1. Android 13+ runtime permission
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      // 2. FCM / iOS permissions
      final notificationSettings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        'Notification Authorization Status: ${notificationSettings.authorizationStatus}',
      );

      // Refresh and sync token if granted
      await _retrieveAndSyncToken();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  /// Retrieves device FCM token and syncs it with Firestore for logged-in user.
  Future<void> _retrieveAndSyncToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      debugPrint('FCM Registration Token: $_fcmToken');
      if (_fcmToken != null) {
        await syncTokenWithFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM Token: $e');
    }
  }

  /// Saves the FCM token under the active user profile in Firestore
  Future<void> syncTokenWithFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'devicePlatform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
        debugPrint('FCM Token synced to Firestore for user: ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token with Firestore: $e');
    }
  }
}
