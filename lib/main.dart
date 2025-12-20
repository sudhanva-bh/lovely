import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/router/app_routes.dart';
import 'package:lovely/common/services/profile_service.dart'; // Import ProfileService
import 'package:lovely/common/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the router provider
    final goRouter = ref.watch(goRouterProvider);
    
    // 2. Watch the user profile to determine gender
    final userAsync = ref.watch(userProfileStreamProvider);

    // 3. Determine theme
    final theme = userAsync.when(
      data: (user) => AppTheme.getThemeForGender(user.gender),
      loading: () => AppTheme.getThemeForGender(null), // Default (Pink) while loading
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