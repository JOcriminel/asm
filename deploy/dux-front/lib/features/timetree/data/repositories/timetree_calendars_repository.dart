import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_calendar_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';

/// Repository for managing TimeTree Calendars.
class TimetreeCalendarsRepository {
  final TimetreeApi _api;
  TimetreeCalendarsRepository(this._api);

  /// Fetches the list of all calendars.
  Future<List<TimetreeCalendar>> getCalendars() async {
    try {
      final response = await _api.getCalendars();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeCalendarDto.fromJson)
            .map(TimetreeCalendar.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'getCalendars failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Creates a new calendar.
  Future<TimetreeCalendar> createCalendar({
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final response = await _api.createCalendar({
        'name': name,
        'description': description,
        'color': color,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCalendarDto.fromJson(data);
        return TimetreeCalendar.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'createCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing calendar.
  Future<TimetreeCalendar> updateCalendar({
    required String id,
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final response = await _api.updateCalendar(id, {
        'name': name,
        'description': description,
        'color': color,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCalendarDto.fromJson(data);
        return TimetreeCalendar.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'updateCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes a calendar by ID.
  Future<void> deleteCalendar(String id) async {
    try {
      await _api.deleteCalendar(id);
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'deleteCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Assigns a member to a calendar.
  Future<void> addMemberToCalendar(String calendarId, String memberId) async {
    try {
      await _api.addMemberToCalendar(calendarId, memberId);
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'addMemberToCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Removes a member from a calendar.
  Future<void> removeMemberFromCalendar(String calendarId, String memberId) async {
    try {
      await _api.removeMemberFromCalendar(calendarId, memberId);
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'removeMemberFromCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Sets members of a calendar.
  Future<void> setCalendarMembers(String calendarId, List<String> memberIds) async {
    try {
      await _api.setCalendarMembers(calendarId, memberIds);
    } catch (e) {
      AppLogger.e('TimetreeCalendarsRepository', 'setCalendarMembers failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeCalendarsRepository].
final timetreeCalendarsRepositoryProvider = Provider<TimetreeCalendarsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeCalendarsRepository(TimetreeApi(dio));
});
