import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/features/auth/presentation/login_page.dart';
import 'package:lovely/features/home/home_nav.dart';
import 'package:lovely/features/calculator/pages/calculator_screen.dart';
import 'package:lovely/features/setup/pages/setup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isUnlockedProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  final isUnlocked = ref.watch(isUnlockedProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),

    redirect: (context, state) {
      // 1. LOCK LOGIC
      // Only enforce lock if NOT in debug mode
      // This allows you to bypass the calculator when developing
      if (!kDebugMode && !isUnlocked) {
        if (state.uri.toString() != '/calculator') return '/calculator';
        return null;
      }

      // If unlocked (or we are in debug mode and bypassed it), prevent going back to calc
      // Note: In debug mode, isUnlocked is likely false, so this check naturally allows 
      // you to manually navigate to '/calculator' if you really want to test it.
      if (isUnlocked && state.uri.toString() == '/calculator') {
        return '/';
      }

      // 2. AUTH LOGIC
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final meta = session?.user.userMetadata;
      final hasCompletedSetup = meta?['hasCompletedSetup'] as bool? ?? false;
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToSetup = state.uri.toString() == '/setup';

      if (!isLoggedIn) return isGoingToLogin ? null : '/login';
      if (isLoggedIn && !hasCompletedSetup) {
        return isGoingToSetup ? null : '/setup';
      }
      if (isLoggedIn &&
          hasCompletedSetup &&
          (isGoingToLogin || isGoingToSetup)) {
        return '/';
      }

      return null;
    },
    routes: [
      // Use CustomTransitionPage for smooth entry
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const HomeNav(),
          begin: const Offset(0.0, 1.0), // Slide UP from bottom (Unlock feel)
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransition(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const SetupPage(),
          begin: const Offset(1.0, 0.0), // Slide IN from right (Step forward feel)
        ),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
    ],
  );
});

// Helper for smooth fades
CustomTransitionPage _fadeTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 800), // Slow fade
  );
}

// Helper for slide transitions
CustomTransitionPage _slideTransition({
  required LocalKey key,
  required Widget child,
  required Offset begin, 
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOutCubicEmphasized; 
      final tween = Tween(begin: begin, end: Offset.zero).chain(
        CurveTween(curve: curve),
      );
      
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 700),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}