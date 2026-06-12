import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'app_sizes.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.background,
      fontFamily: 'Inter', // Default system fallback if font not loaded
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: lightColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.roundedL,
          side: BorderSide(color: lightColorScheme.outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: lightColorScheme.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: lightColorScheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: lightColorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: lightColorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        labelStyle: TextStyle(color: lightColorScheme.secondary),
        floatingLabelStyle: TextStyle(color: lightColorScheme.primary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightColorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: lightColorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: lightColorScheme.primary,
        unselectedLabelColor: lightColorScheme.secondary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outline,
        thickness: 1,
        space: AppSpacing.l,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, height: 1.5, color: Color(0xFF94A3B8)), // Slate 400
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.4, color: Color(0xFF94A3B8)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
      ),
      cardTheme: CardThemeData(
        color: darkColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.roundedL,
          side: BorderSide(color: darkColorScheme.outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: darkColorScheme.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: darkColorScheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: darkColorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.roundedM,
          borderSide: BorderSide(color: darkColorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        labelStyle: TextStyle(color: darkColorScheme.secondary),
        floatingLabelStyle: TextStyle(color: darkColorScheme.primary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkColorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: darkColorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: darkColorScheme.primary,
        unselectedLabelColor: darkColorScheme.secondary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outline,
        thickness: 1,
        space: AppSpacing.l,
      ),
    );
  }
}
