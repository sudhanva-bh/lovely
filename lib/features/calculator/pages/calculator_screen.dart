import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart' hide Interval, Stack;
import 'package:lovely/common/router/app_routes.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  String _result = '0';

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4)),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String text) {
    if (_isUnlocking) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (text == 'C') {
        _input = '';
        _result = '0';
      } else if (text == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (text == '=') {
        _handleEquals();
      } else if (text == 'sqrt') {
        _input += 'sqrt(';
      } else if (text == 'log') {
        _input += 'log(';
      } else if (text == 'ln') {
        _input += 'ln(';
      } else {
        _input += text;
      }
    });
  }

  void _handleEquals() {
    String cleanInput = _input.trim();
    if (cleanInput == '69*420' || cleanInput == '69x420') {
      _triggerUnlockSequence();
      return;
    }

    try {
      Parser p = Parser();
      String finalInput = _input
          .replaceAll('x', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265')
          .replaceAll('e', '2.71828182');

      Expression exp = p.parse(finalInput);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String res = eval.toString();
      if (res.endsWith(".0")) {
        _result = res.substring(0, res.length - 2);
      } else {
        _result = eval
            .toStringAsFixed(4)
            .replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
      }
    } catch (e) {
      _result = 'Error';
    }
    setState(() {});
  }

  Future<void> _triggerUnlockSequence() async {
    setState(() => _isUnlocking = true);
    await _animController.forward();

    if (mounted) {
      ref.read(isUnlockedProvider.notifier).state = true;
      _input = '';
      _result = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // LAYER 1: The Calculator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // DISPLAY AREA (Flex reduced slightly to give more room to keys)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _input,
                            style: TextStyle(
                              fontSize: 24,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _result,
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),

                  // KEYPAD AREA
                  Expanded(
                    flex: 6, // Increased flex slightly
                    child: Container(
                      color: colorScheme.surfaceContainerLow,
                      padding: const EdgeInsets.all(12),
                      child: _buildButtonsGrid(colorScheme),
                    ),
                  ),
                ],
              ),
            ),

            // LAYER 2: Unlock Animation
            if (_isUnlocking)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        color: colorScheme.primary,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Naughty Naughty",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Entering secure vault...",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsGrid(ColorScheme colorScheme) {
    final List<String> buttons = [
      'C',
      '⌫',
      '%',
      '÷',
      'sin',
      'cos',
      'tan',
      '^',
      '7',
      '8',
      '9',
      'x',
      '4',
      '5',
      '6',
      '-',
      '1',
      '2',
      '3',
      '+',
      'e',
      '0',
      '.',
      '=',
    ];

    // FIX: Use LayoutBuilder to calculate exact aspect ratio to fit the screen
    return LayoutBuilder(
      builder: (context, constraints) {
        // We have 4 columns
        const int crossAxisCount = 4;
        // We have 6 rows (24 buttons / 4 cols)
        const int rowCount = 6;
        const double spacing = 10.0;

        // Calculate available width and height per item
        // Subtract total spacing from total available dimensions
        final double totalHorizontalSpacing = (crossAxisCount - 1) * spacing;
        final double totalVerticalSpacing = (rowCount - 1) * spacing;

        final double itemWidth =
            (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;
        final double itemHeight =
            (constraints.maxHeight - totalVerticalSpacing) / rowCount;

        // Dynamic aspect ratio
        final double childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio, // Use the calculated ratio
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            return _buildButtonLogic(buttons[index], colorScheme);
          },
        );
      },
    );
  }

  Widget _buildButtonLogic(String text, ColorScheme colorScheme) {
    Color bg = colorScheme.surfaceContainer;
    Color fg = colorScheme.onSurface;

    if (text == 'C') {
      bg = colorScheme.errorContainer;
      fg = colorScheme.onErrorContainer;
    } else if (text == '⌫') {
      bg = colorScheme.tertiaryContainer;
      fg = colorScheme.onTertiaryContainer;
    } else if (text == '=') {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
    } else if ('÷ x - +'.contains(text)) {
      bg = colorScheme.secondaryContainer;
      fg = colorScheme.onSecondaryContainer;
    } else if ('sin cos tan ln log sqrt ^ ( ) % e π'.contains(text)) {
      bg = colorScheme.surface;
      fg = colorScheme.onSurfaceVariant;
    }

    return _ModernCalcButton(
      text: text,
      backgroundColor: bg,
      textColor: fg,
      onPressed: () => _onButtonPressed(text),
    );
  }
}

class _ModernCalcButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _ModernCalcButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          alignment: Alignment.center,
          child: FittedBox(
            // Added FittedBox to ensure text doesn't overflow inside button
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
