import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // You can add signInWithGoogle, etc. here in the future
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});