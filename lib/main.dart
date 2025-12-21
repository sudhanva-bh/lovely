import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/router/app_routes.dart';
import 'package:lovely/common/services/profile_service.dart'; // Import ProfileService
import 'package:lovely/common/services/notification_service.dart'; // Import NotificationService
import 'package:lovely/common/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 1. Initialize Firebase
  // Ensure you have added the google-services.json / GoogleService-Info.plist files
  await Firebase.initializeApp();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen to Auth State Changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // User just logged in (or app opened with session)
        // Check permissions and save the FCM Token
        ref.read(notificationServiceProvider).initializeAndSaveToken();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the router provider
    final goRouter = ref.watch(goRouterProvider);

    // 2. Watch the user profile to determine gender
    final userAsync = ref.watch(userProfileStreamProvider);

    // 3. Determine theme
    final theme = userAsync.when(
      data: (user) => AppTheme.getThemeForGender(user.gender),
      loading: () =>
          AppTheme.getThemeForGender(null), // Default (Pink) while loading
      error: (_, __) => AppTheme.getThemeForGender(null), // Default on error
    );

    return MaterialApp.router(
      title: 'Local.ly',
      debugShowCheckedModeBanner: false,

      // Dynamic Theme
      theme: theme,
      // Force light mode logic (since our 'dark' theme is handled via the dynamic generator for now)
      themeMode: ThemeMode.light,

      // Connect GoRouter
      routerConfig: goRouter,
    );
  }
}
