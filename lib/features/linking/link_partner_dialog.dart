import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lovely/features/profile/controllers/profile_controller.dart';
import 'package:lovely/features/linking/smooth_qr_display.dart';

class LinkPartnerDialog extends StatefulWidget {
  final ProfileController controller;
  final String? initialCode;

  const LinkPartnerDialog({
    super.key,
    required this.controller,
    this.initialCode,
  });

  @override
  State<LinkPartnerDialog> createState() => _LinkPartnerDialogState();
}

class _LinkPartnerDialogState extends State<LinkPartnerDialog> {
  final TextEditingController _partnerCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _partnerCodeController.text = widget.initialCode!;
    }
  }

  void _scanQR() async {
    // Open the new improved scanner page
    final code = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const _SimpleScannerPage()),
    );

    if (code != null && code is String) {
      // 1. Fill the text field (so user sees what was scanned)
      _partnerCodeController.text = code;

      // 2. CHANGED: Automatically trigger the link action!
      if (mounted) {
        widget.controller.linkPartner(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final myCode = widget.controller.myCoupleCode;
        final isLinking = widget.controller.isLinking;
        final isQrLoading = myCode == null;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: theme.colorScheme.surface,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Link Partner",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Smooth QR Section ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Your Linking Code",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SmoothQrDisplay(
                          code: myCode,
                          isLoading: isQrLoading,
                          onRegenerate: () =>
                              widget.controller.regenerateCode(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Input Section ---
                  TextField(
                    controller: _partnerCodeController,
                    textAlign: TextAlign.left,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
                    decoration: InputDecoration(
                      labelText: "Enter Partner's Code",
                      counterText: "",
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        tooltip: "Scan QR",
                        onPressed: _scanQR,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLinking
                          ? null
                          : () => widget.controller.linkPartner(
                              context,
                              _partnerCodeController.text,
                            ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLinking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Link Partner"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Modern Scanner Page
// -----------------------------------------------------------------------------
class _SimpleScannerPage extends StatefulWidget {
  const _SimpleScannerPage();

  @override
  State<_SimpleScannerPage> createState() => _SimpleScannerPageState();
}

class _SimpleScannerPageState extends State<_SimpleScannerPage> {
  // Controller to handle torch, camera switch, etc.
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanBorderColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Haptic feedback
                  HapticFeedback.lightImpact();
                  // Return the code
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),

          // 2. Custom Overlay (Darkened background + Cutout + Borders)
          CustomPaint(
            painter: _ScannerOverlayPainter(
              borderColor: scanBorderColor,
              borderRadius: 24,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: 280,
            ),
            child: Container(),
          ),

          // 3. UI Controls
          SafeArea(
            child: Column(
              children: [
                // -- Header --
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildCircleBtn(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Scan QR Code",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                const Spacer(),

                // -- Hint Text --
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Align code within the frame",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // -- Bottom Controls --
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Torch Toggle
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          final isTorchOn = state.torchState == TorchState.on;
                          return _buildControlBtn(
                            icon: isTorchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            isActive: isTorchOn,
                            onTap: () => controller.toggleTorch(),
                          );
                        },
                      ),
                      const SizedBox(width: 40),
                      // Camera Switch
                      _buildControlBtn(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => controller.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painter for Scanner Overlay
// -----------------------------------------------------------------------------
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double halfSize = cutOutSize / 2;

    // 1. Draw Semi-Transparent Background with Cutout
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Draw Corner Borders
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final double l = borderLength;
    final double r = borderRadius;

    // Top Left
    final tlPath = Path()
      ..moveTo(centerX - halfSize, centerY - halfSize + l)
      ..lineTo(centerX - halfSize, centerY - halfSize + r)
      ..arcToPoint(
        Offset(centerX - halfSize + r, centerY - halfSize),
        radius: Radius.circular(r),
      )
      ..lineTo(centerX - halfSize + l, centerY - halfSize);
    canvas.drawPath(tlPath, borderPaint);

    // Top Right
    final trPath = Path()
      ..moveTo(centerX + halfSize - l, centerY - halfSize)
      ..lineTo(centerX + halfSize - r, centerY - halfSize)
      ..arcToPoint(
        Offset(centerX + halfSize, centerY - halfSize + r),
        radius: Radius.circular(r),
      )
      ..lineTo(centerX + halfSize, centerY - halfSize + l);
    canvas.drawPath(trPath, borderPaint);

    // Bottom Right
    final brPath = Path()
      ..moveTo(centerX + halfSize, centerY + halfSize - l)
      ..lineTo(centerX + halfSize, centerY + halfSize - r)
      ..arcToPoint(
        Offset(centerX + halfSize - r, centerY + halfSize),
        radius: Radius.circular(r),
      )
      ..lineTo(centerX + halfSize - l, centerY + halfSize);
    canvas.drawPath(brPath, borderPaint);

    // Bottom Left
    final blPath = Path()
      ..moveTo(centerX - halfSize + l, centerY + halfSize)
      ..lineTo(centerX - halfSize + r, centerY + halfSize)
      ..arcToPoint(
        Offset(centerX - halfSize, centerY + halfSize - r),
        radius: Radius.circular(r),
      )
      ..lineTo(centerX - halfSize, centerY + halfSize - l);
    canvas.drawPath(blPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
