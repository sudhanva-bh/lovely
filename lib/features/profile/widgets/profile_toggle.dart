import 'package:flutter/material.dart';

class ProfileToggle extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;

  const ProfileToggle({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      width: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: selectedTab == 'him'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _buildToggleOption("Him", 'him', theme),
              _buildToggleOption("Her", 'her', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, String value, ThemeData theme) {
    final isSelected = selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: theme.textTheme.bodyMedium?.fontFamily,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}