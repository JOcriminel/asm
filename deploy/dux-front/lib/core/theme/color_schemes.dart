import 'package:flutter/material.dart';

const Color _lightPrimary = Color(0xFF2196F3); // Blue from the design
const Color _lightOnPrimary = Colors.white;
const Color _lightSecondary = Color(0xFF6B7280); // Gray text
const Color _lightBackground = Color(0xFFF7F8FA); // Light gray background
const Color _lightSurface = Color(0xFFFFFFFF); // White cards
const Color _lightError = Color(0xFFEF4444); // Error red

const Color _darkPrimary = Color(0xFF4A7FC4); 
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
  onSurface: Color(0xFF111827), // Near black text
  error: _lightError,
  onError: Colors.white,
  outline: Color(0xFFE5E7EB), // Soft borders
  outlineVariant: Color(0xFFD1D5DB),
  shadow: Color(0x0A000000), // Very light shadow
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
