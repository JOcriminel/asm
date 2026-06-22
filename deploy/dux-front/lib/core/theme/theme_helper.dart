import 'package:flutter/material.dart';

Color parseHexColor(String hexString, Color fallback) {
  try {
    final hex = hexString.replaceAll('#', '').trim();
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (_) {
    // Ignore error
  }
  return fallback;
}

ThemeData getDynamicTheme(BuildContext context, String? primaryColorHex) {
  final theme = Theme.of(context);
  if (primaryColorHex == null || primaryColorHex.isEmpty) return theme;

  final primaryColor = parseHexColor(primaryColorHex, theme.colorScheme.primary);
  
  final dynamicColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: theme.brightness,
    primary: primaryColor,
  );

  return theme.copyWith(
    colorScheme: dynamicColorScheme,
    primaryColor: primaryColor,
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: primaryColor,
      ),
      iconTheme: theme.appBarTheme.iconTheme?.copyWith(
        color: primaryColor,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: primaryColor.withValues(alpha: 0.3),
      selectionHandleColor: primaryColor,
    ),
  );
}
