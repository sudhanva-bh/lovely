import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/services/preferences_service.dart';
import 'package:lovely/features/profile/controllers/profile_controller.dart';

class SettingsPage extends ConsumerWidget {
  final ProfileController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDisguiseEnabled = ref.watch(disguiseSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final user = controller.fullUser;
          if (user == null) return const SizedBox();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Account Settings ---
              Text(
                "Account",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Push Notifications"),
                      subtitle: const Text(
                        "Receive updates about your partner",
                      ),
                      value: user.notificationsEnabled,
                      onChanged: (val) => controller.toggleNotifications(val),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Privacy / Security Settings ---
              Text(
                "Security",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Disguise as Calculator"),
                      subtitle: const Text(
                        "Show a calculator screen on launch",
                      ),
                      secondary: Icon(
                        Icons.calculate_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      value: isDisguiseEnabled,
                      onChanged: (val) {
                        ref.read(disguiseSettingsProvider.notifier).toggle(val);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- Danger Zone ---
              OutlinedButton.icon(
                onPressed: () => controller.signOut(context),
                icon: Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  "Sign Out",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.error.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
