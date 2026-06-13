import 'package:flutter/material.dart';

const Color _lightPrimary = Color(0xFF679ADE); // Primary
const Color _lightOnPrimary = Colors.white;
const Color _lightSecondary = Color(0xFF8A8582); // Muted
const Color _lightBackground = Color(0xFFDBEEFE); // bg
const Color _lightSurface = Color(0xFFFAFAFA); // surface
const Color _lightError = Color(0xFFEF4444); // rose

const Color _darkPrimary = Color(0xFF4A7FC4); // Primary dark
const Color _darkOnPrimary = Colors.white;
const Color _darkSecondary = Color(0xFF9CA3AF); 
const Color _darkBackground = Color(0xFF0B0F19); 
const Color _darkSurface = Color(0xFF151D30); 
const Color _darkError = Color(0xFFEF4444); 

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _lightPrimary,
  onPrimary: _lightOnPrimary,
  secondary: _lightSecondary,
  onSecondary: Colors.white,
  surface: _lightSurface,
  onSurface: Color(0xFF534B48), // text main
  error: _lightError,
  onError: Colors.white,
  outline: Color(0xFFC5D9F0), // border
  outlineVariant: Color(0xFFC5D9F0),
  shadow: Color(0x1F679ADE), // Primary with opacity 12% is approx 0x1F
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _darkPrimary,
  onPrimary: _darkOnPrimary,
  secondary: _darkSecondary,
  onSecondary: Color(0xFF111827),
  surface: _darkSurface,
  onSurface: Color(0xFFF9FAFB),
  error: _darkError,
  onError: Colors.white,
  outline: Color(0xFF1F2937),
  outlineVariant: Color(0xFF374151),
  shadow: Color(0x1F000000),
);
