import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provides the raw Supabase session stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 2. Checks if the current user has completed setup
final hasCompletedSetupProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (data) {
      final session = data.session;
      if (session == null) return false;
      
      // The logic we discussed earlier: default to false if null
      final meta = session.user.userMetadata;
      return meta?['hasCompletedSetup'] as bool? ?? false;
    },
    error: (_, __) => false,
    loading: () => false,
  );
});