import 'package:flutter/material.dart';

const Color _lightPrimary = Color(0xFF4F46E5); // Indigo 600
const Color _lightOnPrimary = Colors.white;
const Color _lightSecondary = Color(0xFF4B5563); // Gray 600
const Color _lightBackground = Color(0xFFF9FAFB); // Gray 50
const Color _lightSurface = Colors.white;
const Color _lightError = Color(0xFFDC2626); // Red 600

const Color _darkPrimary = Color(0xFF6366F1); // Indigo 500
const Color _darkOnPrimary = Colors.white;
const Color _darkSecondary = Color(0xFF9CA3AF); // Gray 400
const Color _darkBackground = Color(0xFF0B0F19); // Slate dark 950
const Color _darkSurface = Color(0xFF151D30); // Slate dark 900
const Color _darkError = Color(0xFFEF4444); // Red 500

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _lightPrimary,
  onPrimary: _lightOnPrimary,
  secondary: _lightSecondary,
  onSecondary: Colors.white, // Gray 900
  surface: _lightSurface,
  onSurface: Color(0xFF111827), // Gray 900
  error: _lightError,
  onError: Colors.white,
  outline: Color(0xFFE5E7EB), // Gray 200 (for thin borders)
  outlineVariant: Color(0xFFD1D5DB), // Gray 300
  shadow: Color(0x0A000000),
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _darkPrimary,
  onPrimary: _darkOnPrimary,
  secondary: _darkSecondary,
  onSecondary: Color(0xFF111827), // Gray 50
  surface: _darkSurface,
  onSurface: Color(0xFFF9FAFB), // Gray 50
  error: _darkError,
  onError: Colors.white,
  outline: Color(0xFF1F2937), // Gray 800
  outlineVariant: Color(0xFF374151), // Gray 700
  shadow: Color(0x1F000000),
);
