import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
  Map<String, dynamic>? _pendingInitialData;
  Map<String, dynamic>? get pendingInitialData => _pendingInitialData;

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

      // 3. Initialize Timezones for Native OS Scheduled Reminders
      try {
        tz.initializeTimeZones();
      } catch (tzErr) {
        debugPrint('Timezone initialization error: $tzErr');
      }

      // 4. Configure Foreground Presentation Options
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
          _pendingInitialData = initialMessage.data;
          // Fallback timer in case splash screen does not consume it
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (_pendingInitialData != null) {
              handlePendingInitialNotification();
            }
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

  /// Dispatches pending cold-start push navigation once the initial screen/Home is ready.
  void handlePendingInitialNotification() {
    if (_pendingInitialData != null) {
      final data = _pendingInitialData!;
      _pendingInitialData = null;
      _handleNotificationNavigation(data);
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
        if (routeStr == '/cart' ||
            routeStr == AppRoutes.cart ||
            data['type'] == 'abandoned_cart') {
          navState.pushNamed(AppRoutes.cart);
        } else if (routeStr == '/orders' ||
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

  /// Retrieves device FCM token, subscribes to broadcast topics, and syncs it with Firestore.
  Future<void> _retrieveAndSyncToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      debugPrint('FCM Registration Token: $_fcmToken');
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        // Automatically subscribe device to broadcast topics
        try {
          await _fcm.subscribeToTopic('all_users');
          await _fcm.subscribeToTopic('broadcast_deals');
          debugPrint('Subscribed to FCM topics: all_users, broadcast_deals');
        } catch (topicErr) {
          debugPrint('Topic subscription error: $topicErr');
        }

        await syncTokenWithFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM Token: $e');
    }
  }

  /// Saves the FCM token under top-level 'fcm_tokens' collection (for all devices, including guests)
  /// and under the active user's profile in 'users/{userId}' when logged in.
  Future<void> syncTokenWithFirestore(String token) async {
    if (token.isEmpty) return;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final safeDocId = token.replaceAll('/', '_');

      // 1. Universal Device Registry in 'fcm_tokens' collection
      await _firestore.collection('fcm_tokens').doc(safeDocId).set({
        'token': token,
        'userId': currentUser?.uid,
        'userEmail': currentUser?.email,
        'devicePlatform': defaultTargetPlatform.name,
        'subscribedTopics': ['all_users', 'broadcast_deals'],
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      // 2. User Profile Sync (if authenticated)
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'devicePlatform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
        debugPrint('FCM Token synced to Firestore for user: ${currentUser.uid}');
      } else {
        debugPrint('FCM Device Token registered for guest user in fcm_tokens');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token with Firestore: $e');
    }
  }

  static const int _abandonedCartNotificationId = 99901;

  /// Schedules a catchy, friendly Hinglish reminder when items remain in cart.
  /// Automatically resets any previous timer so user is never spammed.
  Future<void> scheduleAbandonedCartReminder({
    Duration delay = const Duration(hours: 2),
    int itemCount = 1,
    String? sampleItemName,
  }) async {
    try {
      await cancelAbandonedCartReminder();

      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

      const title = '🛒 Arrey! Cart me kuch reh gaya hai...';
      final body = (sampleItemName != null && sampleItemName.trim().isNotEmpty)
          ? '$sampleItemName aur baaki items aapke cart me intezar kar rahe hain! Abhi checkout karein aur 10 minute me delivery paayein ⚡'
          : 'Aapke cart me $itemCount items bache hue hain! Stock khatam hone se pehle abhi checkout karein 🚀';

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
        styleInformation: BigTextStyleInformation(body),
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

      await _localNotifications.zonedSchedule(
        _abandonedCartNotificationId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'route': AppRoutes.cart,
          'screen': 'cart',
          'type': 'abandoned_cart',
        }),
      );

      debugPrint('Scheduled Hinglish abandoned cart reminder at $scheduledTime ($body)');
    } catch (e) {
      debugPrint('Error scheduling abandoned cart reminder: $e');
    }
  }

  /// Cancels any scheduled abandoned cart notification when user checks out or empties cart.
  Future<void> cancelAbandonedCartReminder() async {
    try {
      await _localNotifications.cancel(_abandonedCartNotificationId);
      debugPrint('Cancelled abandoned cart reminder');
    } catch (e) {
      debugPrint('Error cancelling abandoned cart reminder: $e');
    }
  }
}
