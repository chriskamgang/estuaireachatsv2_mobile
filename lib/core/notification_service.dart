import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// =============================================================================
// Background message handler (top-level, hors de toute classe)
// =============================================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase init deja fait dans main
  print('Background message: ${message.notification?.title}');
}

// =============================================================================
// NotificationService singleton
// =============================================================================

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'estuaire_achats_high';
  static const String _channelName = 'EstuaireAchats';
  static const String _channelDesc = 'Notifications importantes EstuaireAchats';

  /// Initialise Firebase Messaging + notifications locales.
  /// Tout est entoure de try/catch : si Firebase n'est pas configure,
  /// l'app continue de fonctionner normalement.
  Future<void> init() async {
    try {
      await _initLocalNotifications();
      await _initFCM();
    } catch (e) {
      print('NotificationService.init error (Firebase may not be configured): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Local notifications setup
  // ---------------------------------------------------------------------------

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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Cree le canal Android haute priorite (style WhatsApp heads-up)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigation au tap : peut etre etendu avec go_router si besoin
    print('Notification tapped: ${response.payload}');
  }

  // ---------------------------------------------------------------------------
  // FCM setup
  // ---------------------------------------------------------------------------

  Future<void> _initFCM() async {
    // Demande la permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permission: ${settings.authorizationStatus}');

    // Recupere et envoie le token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Ecoute les changements de token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _registerToken(newToken);
    });

    // S'abonne au topic global
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (e) {
      print('Subscribe to topic error: $e');
    }

    // Foreground : affiche une notification locale
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data['type'] ?? '',
        );
      }
    });

    // Background tap : app ouverte depuis notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background notification: ${message.data}');
      // Navigation possible ici via un GlobalKey<NavigatorState> si besoin
    });
  }

  // ---------------------------------------------------------------------------
  // Envoie le token FCM au backend
  // ---------------------------------------------------------------------------

  Future<void> _registerToken(String token) async {
    try {
      await ApiService().post(
        '/notifications/register-token',
        data: {'token': token},
      );
      print('FCM token registered: $token');
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Affiche une notification locale (foreground)
  // ---------------------------------------------------------------------------

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        // Style heads-up
        fullScreenIntent: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('showLocalNotification error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Recupere le nombre de notifs non lues
  // ---------------------------------------------------------------------------

  Future<int> getUnreadCount() async {
    try {
      final response = await ApiService().get('/notifications/unread-count');
      return (response.data['data']['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('getUnreadCount error: $e');
      return 0;
    }
  }
}
