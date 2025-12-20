// smooth_qr_display.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
// Import your new helper
import 'share_helper.dart';

class SmoothQrDisplay extends StatefulWidget {
  final String? code;
  final bool isLoading;
  final VoidCallback onRegenerate;

  const SmoothQrDisplay({
    super.key,
    required this.code,
    required this.isLoading,
    required this.onRegenerate,
  });

  @override
  State<SmoothQrDisplay> createState() => _SmoothQrDisplayState();
}

class _SmoothQrDisplayState extends State<SmoothQrDisplay> {
  // State to show a loader on the share button specifically
  bool _isSharing = false;

  Future<void> _handleShare() async {
    if (widget.code == null) return;

    setState(() => _isSharing = true);

    // Call our new helper
    await ShareHelper.shareQrWithImage(widget.code!);

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: (widget.code != null && !widget.isLoading)
          ? _buildQrContent(context, theme, widget.code!)
          : _buildSkeleton(context, theme),
    );
  }

  Widget _buildSkeleton(BuildContext context, ThemeData theme) {
    return Column(
      key: const ValueKey('skeleton'),
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 30,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildQrContent(BuildContext context, ThemeData theme, String data) {
    return Column(
      key: ValueKey(data),
      children: [
        QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 150.0,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: theme.colorScheme.primary,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Copy Button
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!')),
                );
              },
            ),
            const SizedBox(width: 6),

            // Share Button
            IconButton(
              onPressed: _isSharing ? null : _handleShare,
              icon: _isSharing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.share_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(width: 6),

            // Regenerate Button
            IconButton(
              onPressed: widget.onRegenerate,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
