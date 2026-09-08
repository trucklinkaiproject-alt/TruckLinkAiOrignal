import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import '../../Core/Constants/firebase_options.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('[PushNotificationService] Background message received: ${message.messageId} | ${message.notification?.title}');
  } catch (e) {
    debugPrint('[PushNotificationService] Error in background handler: $e');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelId = 'trucklink_notifications';
  static const String channelName = 'TruckLink Notifications';
  static const String channelDescription =
      'High importance notifications for shipment alerts, chat messages, and driver assignments';

  bool _isInitialized = false;

  /// Initialize Firebase Messaging & Flutter Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Request notification permissions
      await requestPermissions();

      // 2. Configure Foreground Presentation Options
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('[PushNotificationService] setForegroundNotificationPresentationOptions error: $e');
      }

      // 3. Initialize Flutter Local Notifications (Mobile only)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _initLocalNotifications();
      }

      // 4. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Listen to background message tap events
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushNotificationService] App opened from background notification tap');
        NotificationNavigationService().handleNotificationTap(message.data);
      });

      // 6. Check for initial message from terminated state
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[PushNotificationService] App launched from terminated notification tap');
        NotificationNavigationService().setPendingNotification(initialMessage.data);
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
    }
  }

  /// Request Notification Permissions (Handles Android 13+ & iOS)
  Future<bool> requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      debugPrint('[PushNotificationService] Notification permission status: ${settings.authorizationStatus}');
      return isAuthorized;
    } catch (e) {
      debugPrint('[PushNotificationService] Request permission error: $e');
      return false;
    }
  }

  /// Initialize Local Notification Plugin & Android Channel
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            NotificationNavigationService().handleNotificationTap(data);
          } catch (e) {
            debugPrint('[PushNotificationService] Error parsing local notification payload: $e');
          }
        }
      },
    );

    // Create high-importance Android Notification Channel
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Display a heads-up local notification when FCM arrives in Foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[PushNotificationService] Foreground FCM received: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    final String title = notification?.title ?? data['title'] ?? 'TruckLink AI';
    final String body = notification?.body ?? data['body'] ?? '';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final int notifId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch).abs();

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
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

      await _localNotifications.show(
        notifId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    }
  }
}
