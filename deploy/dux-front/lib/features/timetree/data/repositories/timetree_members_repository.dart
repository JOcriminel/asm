import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';

/// Repository for managing TimeTree Members.
class TimetreeMembersRepository {
  final TimetreeApi _api;
  TimetreeMembersRepository(this._api);

  /// Fetches the list of all members.
  Future<List<TimetreeMember>> getMembers() async {
    try {
      final response = await _api.getMembers();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeMemberDto.fromJson)
            .map(TimetreeMember.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'getMembers failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Creates a new member.
  Future<TimetreeMember> createMember({
    required String username,
    required String fullName,
    required String email,
    required String role,
    bool? canCreateAgendas,
    bool? canAddMembers,
    List<String>? calendarIds,
  }) async {
    try {
      final response = await _api.createMember({
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role,
        if (canCreateAgendas != null) 'canCreateAgendas': canCreateAgendas,
        if (canAddMembers != null) 'canAddMembers': canAddMembers,
        if (calendarIds != null)
          'calendars': calendarIds.map((cid) => {'id': int.tryParse(cid) ?? 0}).toList(),
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeMemberDto.fromJson(data);
        return TimetreeMember.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'createMember failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing member.
  Future<TimetreeMember> updateMember({
    required String id,
    required String username,
    required String fullName,
    required String email,
    required String role,
    bool? canCreateAgendas,
    bool? canAddMembers,
    String? profilePicture,
    List<String>? calendarIds,
  }) async {
    try {
      final response = await _api.updateMember(id, {
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role,
        if (canCreateAgendas != null) 'canCreateAgendas': canCreateAgendas,
        if (canAddMembers != null) 'canAddMembers': canAddMembers,
        if (profilePicture != null) 'profilePicture': profilePicture,
        if (calendarIds != null)
          'calendars': calendarIds.map((cid) => {'id': int.tryParse(cid) ?? 0}).toList(),
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeMemberDto.fromJson(data);
        return TimetreeMember.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'updateMember failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes a member by ID.
  Future<void> deleteMember(String id) async {
    try {
      await _api.deleteMember(id);
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'deleteMember failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Adds a member to a calendar.
  Future<void> addMemberToCalendar(String calendarId, String memberId) async {
    try {
      await _api.addMemberToCalendar(calendarId, memberId);
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'addMemberToCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Removes a member from a calendar.
  Future<void> removeMemberFromCalendar(String calendarId, String memberId) async {
    try {
      await _api.removeMemberFromCalendar(calendarId, memberId);
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'removeMemberFromCalendar failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Sets all members of a calendar.
  Future<void> setCalendarMembers(String calendarId, List<String> memberIds) async {
    try {
      await _api.setCalendarMembers(calendarId, memberIds);
    } catch (e) {
      AppLogger.e('TimetreeMembersRepository', 'setCalendarMembers failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeMembersRepository].
final timetreeMembersRepositoryProvider = Provider<TimetreeMembersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeMembersRepository(TimetreeApi(dio));
});
