import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Widget? avatar;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = theme.colorScheme.primary;
    final activeFg = theme.colorScheme.onPrimary;
    
    final inactiveBg = theme.colorScheme.surface;
    final inactiveFg = theme.colorScheme.onBackground;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        avatar: avatar,
        checkmarkColor: activeFg,
        showCheckmark: false,
        selectedColor: activeBg,
        backgroundColor: inactiveBg,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: isSelected ? activeFg : inactiveFg,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.roundedFull,
          side: BorderSide(
            color: isSelected ? activeBg : theme.colorScheme.outline,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
        elevation: 0,
        pressElevation: 0,
      ),
    );
  }
}
