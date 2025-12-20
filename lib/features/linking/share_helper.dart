import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  /// The specific text template for sharing
  static String _buildShareText(String code) {
    return "Hey, Lovely! 💕\n\n"
        "I'm using Lovely to connect with my partner. "
        "Pair with me using my code: ✨ *$code* ✨\n"
        // Updated to use your Netlify Redirect Bridge (Clickable in WhatsApp)
        "or using: https://lovely-app.netlify.app/?linkingCode=$code\n\n"
        // Updated download link
        "Download the app here: https://lovely-app.netlify.app/download";
  }

  /// Generates the image and triggers the native share sheet
  static Future<void> shareQrWithImage(String code) async {
    try {
      final file = await _generateShareImage(code);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _buildShareText(code),
        subject: 'Let\'s link up on Lovely!',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  /// Draws the QR code onto the preset background image
  static Future<File> _generateShareImage(String code) async {
    // 1. Load the background image
    final ui.Image bgImage = await _loadAssetImage(
      'assets/share/share_card_2.png',
    );

    final double width = bgImage.width.toDouble();
    final double height = bgImage.height.toDouble();

    // 2. Create a canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 3. Draw the background
    final paint = Paint();
    canvas.drawImage(bgImage, Offset.zero, paint);

    // 4. Define QR Code Layout (Re-calibrated to be 5% smaller and centered)

    // Reduced size factor from 0.38 to 0.36 (approx 5% smaller)
    final double qrSize = height * 0.36;

    // Centered horizontally (automatic based on new size)
    final double qrX = (width - qrSize) / 2;

    // Adjusted vertical start to keep the exact center point.
    // Previous center was at ~53.5% height. New Y = 0.535 - (0.36/2) = 0.355
    final double qrY = height * 0.355;

    // 5. Configure the QR Painter
    final qrPainter = QrPainter(
      data: code,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.circle,
        color: Color(0xFF8E2456), // Deep Wine color to match the "Lovely" logo
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: Color(0xFF8E2456), // Matching Deep Wine color
      ),
      // No background color needed as the image box is already light pink
    );

    // 6. Draw the QR Code
    canvas.save();
    canvas.translate(qrX, qrY);
    qrPainter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    // 7. Render to file
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // 8. Save to temp storage
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/lovely_share_code.png');
    await tempFile.writeAsBytes(buffer);

    return tempFile;
  }

  /// Helper to load ui.Image from asset bundle
  static Future<ui.Image> _loadAssetImage(String key) async {
    final ByteData data = await rootBundle.load(key);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }
}
