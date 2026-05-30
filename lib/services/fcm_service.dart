import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'backend_service.dart';

/// FCM Service — handles Firebase Cloud Messaging for background push notifications.
///
/// Setup steps (see HOW_TO_RUN.md):
///   1. Create Firebase project at console.firebase.google.com
///   2. Add Android app → download google-services.json → place in android/app/
///   3. Enable Cloud Messaging in Firebase Console
///   4. Set FIREBASE_SERVICE_ACCOUNT_PATH in backend/.env
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'medisure_reminders',
    'MediSure Reminders',
    description: 'Medicine reminders and health alerts from MediSure',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM. Call this from main() after Firebase.initializeApp().
  Future<void> init(String? userId) async {
    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied — push notifications disabled');
      return;
    }

    // Set up local notifications channel (Android)
    await _setupLocalNotifications();

    // Get FCM token and register with backend
    await _registerToken(userId);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed');
      _registerToken(userId);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ FCM initialized');
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Local notification tapped: ${details.payload}');
      },
    );

    // Create Android notification channel
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  Future<void> _registerToken(String? userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null');
        return;
      }

      debugPrint('FCM Token: ${token.substring(0, 20)}...');

      // Register with backend if user is logged in
      if (userId != null && userId.isNotEmpty) {
        final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
        await BackendService.instance.registerFcmToken(userId, token, platform);
        debugPrint('✅ FCM token registered with backend');
      }
    } catch (e) {
      debugPrint('FCM token registration error: $e');
    }
  }

  /// Show a local notification when app is in foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  /// Handle notification tap — navigate to relevant screen.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM notification tapped: ${message.data}');
    final type = message.data['type'];

    // Navigate based on notification type
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'reminder':
        // Navigate to reminders screen
        debugPrint('Navigate to reminders');
        break;
      case 'order':
        // Navigate to orders screen
        debugPrint('Navigate to orders');
        break;
      case 'expiry':
        // Navigate to expiry tracking
        debugPrint('Navigate to expiry tracking');
        break;
    }
  }

  /// Update FCM token when user logs in.
  Future<void> onUserLogin(String userId) async {
    await _registerToken(userId);
  }

  /// Clear FCM token on logout.
  Future<void> onUserLogout() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted on logout');
    } catch (e) {
      debugPrint('FCM token delete error: $e');
    }
  }
}

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.notification?.title}');
  // Background messages are handled by the OS notification tray automatically.
  // Add any background processing here if needed.
}
