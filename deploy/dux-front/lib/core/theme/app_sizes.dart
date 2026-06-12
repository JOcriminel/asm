import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapS = SizedBox(width: s, height: s);
  static const SizedBox gapM = SizedBox(width: m, height: m);
  static const SizedBox gapL = SizedBox(width: l, height: l);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
}

class AppBorderRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;

  static final BorderRadius roundedS = BorderRadius.circular(s);
  static final BorderRadius roundedM = BorderRadius.circular(m);
  static final BorderRadius roundedL = BorderRadius.circular(l);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedFull = BorderRadius.circular(999.0);
}

class AppShadows {
  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.01),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
