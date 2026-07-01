import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

/// Service to manage and persist whether the user has viewed specific tutorials/walkthroughs.
class TutorialService {
  final StorageService _storageService;

  static const String _keyIntro = 'has_seen_intro_walkthrough';
  static const String _keyDashboard = 'has_seen_dashboard_tour';
  static const String _keyCalendar = 'has_seen_calendar_tour';

  TutorialService(this._storageService);

  /// Checks if the user has completed the global onboarding intro slides.
  Future<bool> hasSeenIntro() async {
    final val = await _storageService.read(_keyIntro);
    return val == 'true';
  }

  /// Sets the state of the global onboarding intro slides.
  Future<void> setSeenIntro(bool seen) async {
    await _storageService.write(_keyIntro, seen ? 'true' : 'false');
  }

  /// Checks if the user has completed the Dux Mobile Dashboard tutorial.
  Future<bool> hasSeenDashboardTour() async {
    final val = await _storageService.read(_keyDashboard);
    return val == 'true';
  }

  /// Sets the state of the Dux Mobile Dashboard tutorial.
  Future<void> setSeenDashboardTour(bool seen) async {
    await _storageService.write(_keyDashboard, seen ? 'true' : 'false');
  }

  /// Checks if the user has completed the Dux Calendar (TimeTree) view tutorial.
  Future<bool> hasSeenCalendarTour() async {
    final val = await _storageService.read(_keyCalendar);
    return val == 'true';
  }

  /// Sets the state of the Dux Calendar (TimeTree) view tutorial.
  Future<void> setSeenCalendarTour(bool seen) async {
    await _storageService.write(_keyCalendar, seen ? 'true' : 'false');
  }

  /// Resets all tutorial states back to not-seen (for debugging or user preferences).
  Future<void> resetAll() async {
    await _storageService.delete(_keyIntro);
    await _storageService.delete(_keyDashboard);
    await _storageService.delete(_keyCalendar);
  }
}

/// Provider for the TutorialService
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TutorialService(storage);
});
