import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/services/update_service.dart';
import 'package:lovely/common/router/app_routes.dart'; // Needed for rootNavigatorKey
import 'package:ota_update/ota_update.dart';

class UpdateListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<UpdateListenerWrapper> createState() =>
      _UpdateListenerWrapperState();
}

class _UpdateListenerWrapperState extends ConsumerState<UpdateListenerWrapper> {
  @override
  void initState() {
    super.initState();
    // Run the check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await ref.read(updateServiceProvider).checkForUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(AppUpdateInfo info) {
    // 1. Get the global navigator context to avoid "No Navigator" errors
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    showDialog(
      context: navContext,
      // Prevent clicking outside if mandatory
      barrierDismissible: !info.isMandatory,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // 2. Wrap in PopScope to intercept Back Button
        return PopScope(
          canPop: !info
              .isMandatory, // If mandatory, CANNOT pop (back button disabled)
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Optional: Show a toast or shake animation indicating action is required
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: colorScheme.surface,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. Header Icon ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. Title ---
                  Text(
                    "Update Available",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // --- 3. Version Badge ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "v${info.version}",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. Content / Notes ---
                  if (info.releaseNotes != null &&
                      info.releaseNotes!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What's New:",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        info.releaseNotes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Text(
                      "A new version of the app is ready for you.\nUpdate now for the best experience!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 5. Buttons ---
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        // For mandatory updates, we usually DO NOT pop the dialog
                        // until the update starts, or we let the progress dialog take over.
                        Navigator.pop(context);
                        _startUpdate(info.url, navContext);
                      },
                      style: FilledButton.styleFrom(
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Update Now",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Only show "Maybe Later" if NOT mandatory
                  if (!info.isMandatory) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text("Maybe Later"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startUpdate(String url, BuildContext context) {
    // Show a polished progress dialog
    // We also make this non-dismissible for safety
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false, // Prevent back button during download
        child: _DownloadProgressDialog(),
      ),
    );

    // Start download
    ref
        .read(updateServiceProvider)
        .downloadAndInstall(url)
        .listen(
          (OtaEvent event) {
            if (event.status == OtaStatus.DOWNLOADING) {
              // Future: Update progress UI here
            } else if (event.status == OtaStatus.INSTALLING) {
              // Android takes over
            }
          },
          onError: (e) {
            // Safely close the progress dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Update failed: $e"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Downloading Update...",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please wait while we make things better for you.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
