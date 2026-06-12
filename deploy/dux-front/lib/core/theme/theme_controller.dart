import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

const String _themeModeKey = 'app_theme_mode';

class ThemeController extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeController(this._storageService) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await _storageService.read(_themeModeKey);
      if (savedTheme != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // Fallback to system theme on error
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    try {
      await _storageService.write(_themeModeKey, themeMode.toString());
    } catch (e) {
      // Ignore save errors
    }
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ThemeController(storageService);
});
