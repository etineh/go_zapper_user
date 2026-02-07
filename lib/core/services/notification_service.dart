import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');
  log('Data: ${message.data}');
  // FCM will auto-display the notification via the Notification payload
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notificationCheckKey = 'last_notification_check';
  static const String _notificationPermissionAskedKey =
      'notification_permission_asked';

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        log('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Delivery updates channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'delivery_updates',
          'Delivery Updates',
          description: 'Notifications about your delivery status',
          importance: Importance.high,
        ),
      );

      // High importance channel for FCM
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Important notifications from GoZapper',
          importance: Importance.high,
        ),
      );
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> initializeFirebase() async {
    try {
      // Request permission for iOS
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      await getFCMToken();

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle initial message if app was opened from notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        log('FCM Token refreshed: $newToken');
        sendDeviceTokenToBackend(newToken);
      });

      log('Firebase Messaging initialized');
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $token');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send device token to backend
  Future<void> sendDeviceTokenToBackend([String? token]) async {
    try {
      final deviceToken = token ?? await getFCMToken();
      if (deviceToken == null) {
        log('No device token available to send');
        return;
      }

      final apiClient = ApiClient();
      await apiClient.put(
        AppConstants.deviceTokenEndpoint,
        data: {'deviceToken': deviceToken},
      );
      log('General log: FCM token sent to backend $deviceToken');
    } catch (e) {
      log('Error sending device token to backend: $e');
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    log('Received foreground message: ${message.messageId}');
    log('Data: ${message.data}');

    // Show local notification when app is in foreground
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'GoZapper',
        body: notification.body ?? 'You have a new notification',
        payload: message.data.toString(),
      );
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notifications from GoZapper',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    log('Notification tapped: ${message.messageId}');
    log('Data: ${message.data}');
// [log] Data: {type: delivery_completed, title: Delivery Completed, message: Your delivery 697b9aB6EL has been completed successfully!}
    // TODO: Navigate to appropriate screen based on notification type
    // You can use the message.data to determine where to navigate
  }
  /*
   DioExceptionType.badResponse
I/flutter ( 4942): ║    {
I/flutter ( 4942): ║         "error": "service delivery_grpc not found in Consul or direct URLs",
I/flutter ( 4942): ║         "message": "Internal Server Error"
I/flutter ( 4942): ║    }
   */

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    // Save that we've asked for permission
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionAskedKey, true);

    return status.isGranted;
  }

  /// Check if we should show the notification activation dialog
  /// Returns true if 5 days have passed since last check
  Future<bool> shouldShowActivationDialog() async {
    // First check if notifications are already enabled
    final isEnabled = await areNotificationsEnabled();
    if (isEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_notificationCheckKey);

    if (lastCheck == null) {
      // First time, save current time and show dialog
      await _saveLastCheckTime();
      return true;
    }

    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final now = DateTime.now();
    final difference = now.difference(lastCheckTime).inDays;

    if (difference >= 5) {
      // 5 days have passed, show dialog
      await _saveLastCheckTime();
      return true;
    }

    return false;
  }

  /// Save the current time as last notification check
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _notificationCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Open app settings for the user to manually enable notifications
  Future<void> openSettings() async {
    await Permission.notification.request();
  }

  /// Show a test notification
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'GoZapper Notifications Enabled',
      'You will now receive important updates about your deliveries!',
      notificationDetails,
    );
  }

  /// Check if permission has been asked before
  Future<bool> hasAskedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermissionAskedKey) ?? false;
  }

  /// Reset notification check timer (useful for testing)
  Future<void> resetNotificationCheckTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationCheckKey);
  }
}
