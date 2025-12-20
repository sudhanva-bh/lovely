import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lovely/features/profile/controllers/profile_controller.dart';
import 'package:lovely/features/linking/smooth_qr_display.dart';

class LinkPartnerDialog extends StatefulWidget {
  final ProfileController controller;

  const LinkPartnerDialog({super.key, required this.controller});

  @override
  State<LinkPartnerDialog> createState() => _LinkPartnerDialogState();
}

class _LinkPartnerDialogState extends State<LinkPartnerDialog> {
  final TextEditingController _partnerCodeController = TextEditingController();

  void _scanQR() async {
    final code = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const _SimpleScannerPage()),
    );

    if (code != null && code is String) {
      _partnerCodeController.text = code;
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

        // We consider it loading if code is null OR controller explicitly says so
        // This helps the SmoothQrDisplay know when to show the skeleton
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
                      // Allow only A–Z and 0–9
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Z0-9]'),
                      ),

                      // Force uppercase even if pasted
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
                    decoration: InputDecoration(
                      labelText: "Enter Partner's Code",
                      counterText: "", // hides "0/6"
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

class _SimpleScannerPage extends StatelessWidget {
  const _SimpleScannerPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Code")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
