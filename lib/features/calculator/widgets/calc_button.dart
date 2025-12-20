import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const CalcButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Use SizedBox.expand so the button fills the grid cell exactly
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor, // Handles the ripple color automatically
          elevation: 0, // Removes shadow for a cleaner, modern look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Smooth, modern corners
          ),
          padding: EdgeInsets.zero, // Removes internal padding constraints
        ),
        // 2. FittedBox automatically scales the text down if it's too big
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Padding helps text breathe
            child: Text(
              text,
              style: TextStyle(
                fontSize: 26, // Start big; it will scale down if needed
                fontWeight:
                    FontWeight.w400, // Lighter weight looks more premium
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
