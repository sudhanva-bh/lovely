import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class LinkingSuccessDialog extends StatefulWidget {
  const LinkingSuccessDialog({super.key});

  @override
  State<LinkingSuccessDialog> createState() => _LinkingSuccessDialogState();
}

class _LinkingSuccessDialogState extends State<LinkingSuccessDialog> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    // Play immediately on open
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stack allows us to paint confetti on top of the dialog
    return Stack(
      alignment: Alignment.center,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.pinkAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Connected!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          content: const Text(
            "You and your partner are now linked.\nLet the love begin! 💕",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Awesome"),
            ),
          ],
        ),
        
        // Confetti Overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.pink,
              Colors.red,
              Colors.purple,
              Colors.white,
            ],
            numberOfParticles: 30,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}