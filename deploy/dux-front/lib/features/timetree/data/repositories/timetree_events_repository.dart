import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_event_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

/// Repository for managing TimeTree Events and their participants.
class TimetreeEventsRepository {
  final TimetreeApi _api;
  TimetreeEventsRepository(this._api);

  /// Fetches events in a given date range for a set of calendars.
  Future<List<TimetreeEvent>> getEvents({
    List<String>? calendarIds,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _api.getEvents(
        calendarIds: calendarIds,
        start: start.toIso8601String(),
        end: end.toIso8601String(),
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeEventDto.fromJson)
            .map(TimetreeEvent.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'getEvents failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches a single event by ID.
  Future<TimetreeEvent> getEvent(String id) async {
    try {
      final response = await _api.getEvent(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeEventDto.fromJson(data);
        return TimetreeEvent.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'getEvent($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches audit log history for an event by ID.
  Future<List<TimetreeAuditLog>> getEventHistory(String id) async {
    try {
      final baseId = id.split('_rec_').first;
      final response = await _api.getEventHistory(baseId);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeAuditLog.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'getEventHistory($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }


  /// Creates a new event.
  Future<TimetreeEvent> createEvent(TimetreeEvent event) async {
    try {
      final response = await _api.createEvent(event.toDto().toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeEventDto.fromJson(data);
        return TimetreeEvent.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'createEvent failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing event.
  Future<TimetreeEvent> updateEvent(String id, TimetreeEvent event) async {
    try {
      final response = await _api.updateEvent(id, event.toDto().toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeEventDto.fromJson(data);
        return TimetreeEvent.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'updateEvent failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes an event.
  Future<void> deleteEvent(String id) async {
    try {
      await _api.deleteEvent(id);
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'deleteEvent failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Assigns a participant to an event.
  Future<TimetreeEvent> addParticipant(String id, String memberId) async {
    try {
      final response = await _api.addParticipant(id, memberId);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeEventDto.fromJson(data);
        return TimetreeEvent.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'addParticipant failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Removes a participant from an event.
  Future<TimetreeEvent> removeParticipant(String id, String memberId) async {
    try {
      final response = await _api.removeParticipant(id, memberId);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeEventDto.fromJson(data);
        return TimetreeEvent.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'removeParticipant failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Exports events in a given format and filters as bytes.
  Future<List<int>> exportEvents(
    String format, {
    List<String>? calendarIds,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final response = await _api.exportEventsBytes(
        format,
        calendarIds: calendarIds,
        start: start?.toIso8601String(),
        end: end?.toIso8601String(),
      );
      final data = response.data;
      if (data is List<int>) {
        return data;
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeEventsRepository', 'exportEvents failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeEventsRepository].
final timetreeEventsRepositoryProvider = Provider<TimetreeEventsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeEventsRepository(TimetreeApi(dio));
});
