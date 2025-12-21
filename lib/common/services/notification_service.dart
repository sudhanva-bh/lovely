import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService(this._supabase);

  // 1. Request Permission & Get Token
  Future<void> initializeAndSaveToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Request permissions (iOS primarily)
    NotificationSettings settings = await _messaging.requestPermission(
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

  // 2. Save Token to Supabase
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

  // 3. Remove Token on Logout
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