import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_page_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_page.dart';

/// Repository for managing TimeTree Pages.
///
/// Uses [TimetreeApi] configured with the shared auth-intercepted Dio instance.
class TimetreePagesRepository {
  final TimetreeApi _api;
  TimetreePagesRepository(this._api);

  /// Fetches the list of all pages.
  Future<List<TimetreePage>> getPages() async {
    try {
      final response = await _api.getPages();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreePageDto.fromJson)
            .map(TimetreePage.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreePagesRepository', 'getPages failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches a single page by ID.
  Future<TimetreePage> getPage(String id) async {
    try {
      final response = await _api.getPage(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreePageDto.fromJson(data);
        return TimetreePage.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreePagesRepository', 'getPage($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Creates a new page.
  Future<TimetreePage> createPage({
    required String title,
    required String categoryId,
    required int displayOrder,
    required bool active,
    String? allowedRoles,
    String? allowedUsers,
  }) async {
    try {
      final response = await _api.createPage({
        'title': title,
        'categoryId': categoryId,
        'displayOrder': displayOrder,
        'active': active,
        'allowedRoles': allowedRoles,
        'allowedUsers': allowedUsers,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreePageDto.fromJson(data);
        return TimetreePage.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreePagesRepository', 'createPage failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing page.
  Future<TimetreePage> updatePage({
    required String id,
    required String title,
    required String categoryId,
    required int displayOrder,
    required bool active,
    String? allowedRoles,
    String? allowedUsers,
  }) async {
    try {
      final response = await _api.updatePage(id, {
        'title': title,
        'categoryId': categoryId,
        'displayOrder': displayOrder,
        'active': active,
        'allowedRoles': allowedRoles,
        'allowedUsers': allowedUsers,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreePageDto.fromJson(data);
        return TimetreePage.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreePagesRepository', 'updatePage failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes a page by ID.
  Future<void> deletePage(String id) async {
    try {
      await _api.deletePage(id);
    } catch (e) {
      AppLogger.e('TimetreePagesRepository', 'deletePage failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreePagesRepository].
final timetreePagesRepositoryProvider = Provider<TimetreePagesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreePagesRepository(TimetreeApi(dio));
});
