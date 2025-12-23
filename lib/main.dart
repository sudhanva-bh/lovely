import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/router/app_routes.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:lovely/common/services/notification_service.dart';
import 'package:lovely/common/services/preferences_service.dart';
import 'package:lovely/common/theme/app_theme.dart';
// REMOVED: import 'package:lovely/common/widgets/update_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // 3. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
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
    final goRouter = ref.watch(goRouterProvider);
    final userAsync = ref.watch(userProfileStreamProvider);

    final theme = userAsync.when(
      data: (user) => AppTheme.getThemeForGender(user.gender),
      loading: () => AppTheme.getThemeForGender(null),
      error: (_, __) => AppTheme.getThemeForGender(null),
    );

    return MaterialApp.router(
      title: 'Lovely',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.light,
      // REMOVED: UpdateListenerWrapper from builder
      routerConfig: goRouter,
    );
  }
}