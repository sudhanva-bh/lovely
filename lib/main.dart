import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/router/app_routes.dart';
// import 'package:lovely/common/services/auth_service.dart';
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
    // 3. Watch the router provider
    final goRouter = ref.watch(goRouterProvider);

    // ref.read(authServiceProvider).signOut();

    return MaterialApp.router(
      title: 'Local.ly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Auto-switch based on phone settings
      // Connect GoRouter
      routerConfig: goRouter,
    );
  }
}
