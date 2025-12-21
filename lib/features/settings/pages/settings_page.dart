import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/features/profile/controllers/profile_controller.dart';

class SettingsPage extends ConsumerWidget {
  final ProfileController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final user = controller.fullUser;
          if (user == null) return const SizedBox();

          return Column(
            children: [
              SwitchListTile(
                title: const Text("Push Notifications"),
                subtitle: const Text("Receive updates about your partner"),
                value: user.notificationsEnabled,
                onChanged: (val) => controller.toggleNotifications(val),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}
