import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = status.trim().toLowerCase();

    Color bg;
    Color fg;

    switch (normalized) {
      case 'validated':
      case 'delivered':
      case 'active':
        bg = const Color(0xFFD1FAE5); // Green 100
        fg = const Color(0xFF065F46); // Green 800
        break;
      case 'pending':
      case 'in_progress':
      case 'validated_representative':
        bg = const Color(0xFFFEF3C7); // Yellow 100
        fg = const Color(0xFF92400E); // Yellow 800
        break;
      case 'cancelled':
      case 'rejected':
      case 'inactive':
        bg = const Color(0xFFFEE2E2); // Red 100
        fg = const Color(0xFF991B1B); // Red 800
        break;
      case 'created':
      case 'draft':
      default:
        bg = const Color(0xFFDBEAFE); // Blue 100
        fg = const Color(0xFF1E40AF); // Blue 800
        break;
    }

    // Adapt colors for dark theme slightly to be readable
    if (theme.brightness == Brightness.dark) {
      switch (normalized) {
        case 'validated':
        case 'delivered':
        case 'active':
          bg = const Color(0xFF065F46).withValues(alpha: 0.2);
          fg = const Color(0xFF34D399); // Green 400
          break;
        case 'pending':
        case 'in_progress':
        case 'validated_representative':
          bg = const Color(0xFF92400E).withValues(alpha: 0.2);
          fg = const Color(0xFFFBBF24); // Yellow 400
          break;
        case 'cancelled':
        case 'rejected':
        case 'inactive':
          bg = const Color(0xFF991B1B).withValues(alpha: 0.2);
          fg = const Color(0xFFF87171); // Red 400
          break;
        case 'created':
        case 'draft':
        default:
          bg = const Color(0xFF1E40AF).withValues(alpha: 0.2);
          fg = const Color(0xFF60A5FA); // Blue 400
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.roundedFull,
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }
}
