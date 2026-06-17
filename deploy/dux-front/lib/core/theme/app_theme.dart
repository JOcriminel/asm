import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';
import 'app_sizes.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.4),
        bodySmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, height: 1.4),
        labelLarge: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: lightColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: lightColorScheme.outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        labelStyle: TextStyle(color: lightColorScheme.secondary),
        floatingLabelStyle: TextStyle(color: lightColorScheme.primary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: lightColorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.inter().fontFamily,
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
      scaffoldBackgroundColor: darkColorScheme.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        headlineMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: Colors.white),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white),
        bodyLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, height: 1.5, color: Color(0xFF94A3B8)),
        bodyMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.4, color: Color(0xFF94A3B8)),
        bodySmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, height: 1.4, color: Color(0xFF94A3B8)),
        labelLarge: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        labelStyle: TextStyle(color: darkColorScheme.secondary),
        floatingLabelStyle: TextStyle(color: darkColorScheme.primary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          fontFamily: GoogleFonts.inter().fontFamily,
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
