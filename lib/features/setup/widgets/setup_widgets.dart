import 'package:flutter/material.dart';

// --- Header Widget ---
class SetupStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const SetupStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.favorite,
                size: 50,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// --- Gender Selector Group ---
class GenderSelector extends StatelessWidget {
  final String selectedGender;
  final Function(String) onSelect;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: GenderCard(
            label: "Male",
            icon: Icons.male_rounded,
            isSelected: selectedGender == "Male",
            onTap: () => onSelect("Male"),
            activeColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GenderCard(
            label: "Female",
            icon: Icons.female_rounded,
            isSelected: selectedGender == "Female",
            onTap: () => onSelect("Female"),
            activeColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GenderCard(
            label: "Other",
            icon: Icons.transgender_rounded,
            isSelected: selectedGender == "Other",
            onTap: () => onSelect("Other"),
            isRainbow: true,
          ),
        ),
      ],
    );
  }
}

// --- Individual Gender Card ---
class GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool isRainbow;

  const GenderCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
    this.isRainbow = false,
  });

  @override
  Widget build(BuildContext context) {
    const rainbowGradient = LinearGradient(
      colors: [
        Colors.red, Colors.orange, Colors.yellow, Colors.green,
        Colors.blue, Colors.indigo, Colors.purple,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    Border? border;
    if (isSelected && !isRainbow) {
      border = Border.all(color: activeColor!, width: 2);
    } else if (!isSelected) {
      border = Border.all(color: Colors.grey.shade200, width: 1.5);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? (isRainbow ? Colors.white : activeColor!.withOpacity(0.1))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: border,
          gradient: (isSelected && isRainbow) ? rainbowGradient : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (isRainbow ? Colors.purple : activeColor!)
                    .withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Container(
          margin: (isSelected && isRainbow)
              ? const EdgeInsets.all(3)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: (isSelected && isRainbow) ? Colors.white : null,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRainbow && isSelected)
                ShaderMask(
                  shaderCallback: (bounds) =>
                      rainbowGradient.createShader(bounds),
                  child: Icon(icon, size: 40, color: Colors.white),
                )
              else
                Icon(
                  icon,
                  size: 40,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                ),
              const SizedBox(height: 8),
              if (isRainbow && isSelected)
                ShaderMask(
                  shaderCallback: (bounds) =>
                      rainbowGradient.createShader(bounds),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Common Input Decoration ---
InputDecoration getSetupInputDecoration(
    BuildContext context, String label, IconData icon) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    
    labelText: label,
    prefixIcon: Icon(icon, color: colorScheme.primary),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
  );
}