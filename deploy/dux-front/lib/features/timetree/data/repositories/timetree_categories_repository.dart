import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_category_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';

/// Repository for managing TimeTree Categories.
///
/// Uses [TimetreeApi] configured with the shared auth-intercepted Dio instance.
class TimetreeCategoriesRepository {
  final TimetreeApi _api;
  TimetreeCategoriesRepository(this._api);

  /// Fetches the list of all categories.
  Future<List<TimetreeCategory>> getCategories() async {
    try {
      final response = await _api.getCategories();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeCategoryDto.fromJson)
            .map(TimetreeCategory.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'getCategories failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches a single category by ID.
  Future<TimetreeCategory> getCategory(String id) async {
    try {
      final response = await _api.getCategory(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCategoryDto.fromJson(data);
        return TimetreeCategory.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'getCategory($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Creates a new category.
  Future<TimetreeCategory> createCategory(String name, int displayOrder) async {
    try {
      final response = await _api.createCategory({
        'name': name,
        'displayOrder': displayOrder,
        'active': true,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCategoryDto.fromJson(data);
        return TimetreeCategory.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'createCategory failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing category name and/or display order.
  Future<TimetreeCategory> updateCategory(String id, String name, int displayOrder) async {
    try {
      final response = await _api.updateCategory(id, {
        'name': name,
        'displayOrder': displayOrder,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCategoryDto.fromJson(data);
        return TimetreeCategory.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'updateCategory failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes a category by ID.
  Future<void> deleteCategory(String id) async {
    try {
      await _api.deleteCategory(id);
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'deleteCategory failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Toggles a category's activation state.
  Future<TimetreeCategory> toggleCategoryActivation(String id, bool active) async {
    try {
      final response = active
          ? await _api.activateCategory(id)
          : await _api.deactivateCategory(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCategoryDto.fromJson(data);
        return TimetreeCategory.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCategoriesRepository', 'toggleCategoryActivation failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeCategoriesRepository].
final timetreeCategoriesRepositoryProvider = Provider<TimetreeCategoriesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeCategoriesRepository(TimetreeApi(dio));
});
