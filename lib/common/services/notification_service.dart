import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._supabase);

  // 1. Initialize Local Notifications & Create Channel
  Future<void> initLocalNotifications() async {
    // Android Setup
    // Ensure you have an icon named 'ic_launcher' in android/app/src/main/res/mipmap-*
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS Setup
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create Android Channel (Required for Android 8.0+)
    const channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // 2. Request Permission, Init Local Notifs & Get Token
  Future<void> initializeAndSaveToken() async {
    // Initialize local notifications first
    await initLocalNotifications();

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Request permissions (iOS primarily)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Optional: Allow foreground notifications on iOS (heads-up display)
    // This allows iOS to show the system notification banner even when the app is open.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the token
      String? token = await _messaging.getToken();

      if (token != null) {
        await _saveTokenToDatabase(token, user.id);
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken, user.id);
      });
    }
  }

  // 3. Show Foreground Notification Manually
  Future<void> showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // We only show if there is a notification object and it's on Android
    // (iOS handles foreground presentation options automatically if configured above)
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Must match the channel ID created above
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  // 4. Save Token to Supabase
  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      await _supabase.from('fcm_tokens').upsert({
        'token': token,
        'user_id': userId,
        'last_used_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // 5. Remove Token on Logout
  Future<void> removeToken() async {
    try {
      // Get the current token locally to delete only this device's token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _supabase.from('fcm_tokens').delete().eq('token', token);
      }
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});
