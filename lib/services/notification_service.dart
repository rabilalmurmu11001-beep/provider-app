import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../router.dart';
import '../secureStorage.dart';
import '../network.dart';

/// Top-level background message handler for FCM in provider_app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Provider App - Handling background FCM message ID: ${message.messageId}");
  debugPrint("Background data payload: ${message.data}");
}

/// Notification Service for provider_app
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;

  /// Initializes permissions, channels, and FCM listeners
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Request Notification Permissions
    await _requestPermissions();

    // 2. Setup Local Notifications for Foreground heads-up banners
    await _setupLocalNotifications();

    // 3. Presentation options for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Retrieve & Persist FCM Device Token
    await _fetchAndPersistToken();

    // 5. Listen for Token Refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('Provider FCM Token Refreshed: $newToken');
      await TokenRepository().persistFcmToken(newToken);
      await syncTokenWithBackend();
    });

    // 6. Setup Message Handlers
    _setupMessageHandlers();
  }

  /// Request notification permissions (iOS & Android 13+)
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
      'Provider Notification permission status: ${settings.authorizationStatus}',
    );
  }

  /// Initialize flutter_local_notifications plugin and create Android channel
  Future<void> _setupLocalNotifications() async {
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
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationRouting(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Fetch FCM Device Token and save locally
  Future<String?> _fetchAndPersistToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('====================================');
      debugPrint('Provider FCM Device Token: $_fcmToken');
      debugPrint('====================================');
      if (_fcmToken != null) {
        await TokenRepository().persistFcmToken(_fcmToken!);
        await syncTokenWithBackend();
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error fetching Provider FCM Token: $e');
      return null;
    }
  }

  /// Sync the FCM token with the backend API
  Future<void> syncTokenWithBackend() async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('Provider not logged in, skipping FCM token sync with backend');
        return;
      }
      final token = _fcmToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.post('/user/fcm-token', data: {'fcmToken': token});
      debugPrint('Provider FCM Token successfully synced with backend: ${response.statusCode}');
    } catch (e) {
      debugPrint('Failed to sync Provider FCM Token with backend: $e');
    }
  }

  /// Clear the FCM token on the backend upon logout
  Future<void> deleteTokenFromBackend() async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      await dio.delete('/user/fcm-token');
      debugPrint('Provider FCM Token successfully cleared from backend');
    } catch (e) {
      debugPrint('Failed to clear Provider FCM Token from backend: $e');
    }
  }

  /// Setup listeners for foreground messages and notification clicks
  void _setupMessageHandlers() {
    // 1. App in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received: ${message.messageId}');
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 2. App opened from BACKGROUND by user tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Provider App opened from notification in background state');
      _handleNotificationRouting(message.data);
    });

    // 3. App opened from TERMINATED state by user tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Provider App opened from notification in terminated state');
        _handleNotificationRouting(message.data);
      }
    });
  }

  /// Route provider based on notification data payload
  void _handleNotificationRouting(Map<String, dynamic> data) {
    if (data.isEmpty) {
      Future.delayed(const Duration(milliseconds: 600), () {
        router.push('/dashboard');
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      // 1. Check direct route parameter
      if (data.containsKey('route') && data['route'] is String) {
        final route = data['route'] as String;
        if (route.isNotEmpty) {
          router.push(route);
          return;
        }
      }

      // 2. Booking notification
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['id'];
      if (data['type'] == 'booking' && bookingId != null) {
        router.push('/bookings/detail?id=$bookingId');
        return;
      }

      // 3. Chat notification
      final roomId = data['roomId'] ?? data['room_id'];
      if (data['type'] == 'chat' && roomId != null) {
        final senderName = data['senderName'] ?? data['recipientName'] ?? 'Customer';
        router.push('/chat?roomId=$roomId&recipientName=$senderName');
        return;
      }

      // Fallback
      router.push('/dashboard');
    });
  }
}
