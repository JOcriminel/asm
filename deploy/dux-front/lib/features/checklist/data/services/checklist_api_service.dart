import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/checklist_models.dart';

final checklistApiServiceProvider = Provider<ChecklistApiService>((ref) {
  return ChecklistApiService(ref.watch(dioProvider));
});

class ChecklistApiService {
  final Dio _dio;

  ChecklistApiService(this._dio);

  // ============================================
  // GROUPS
  // ============================================
  Future<List<ChecklistGroup>> getGroups() async {
    final response = await _dio.get('/admin/checklists/groups');
    return (response.data as List).map((e) => ChecklistGroup.fromJson(e)).toList();
  }

  Future<ChecklistGroup> createGroup(String name) async {
    final response = await _dio.post('/admin/checklists/groups', data: {'name': name});
    return ChecklistGroup.fromJson(response.data);
  }

  Future<void> deleteGroup(int id) async {
    await _dio.delete('/admin/checklists/groups/$id');
  }

  // ============================================
  // FAMILY MAPPINGS
  // ============================================
  Future<List<ChecklistFamilyMapping>> getFamiliesByGroup(int groupId) async {
    final response = await _dio.get('/admin/checklists/groups/$groupId/families');
    return (response.data as List).map((e) => ChecklistFamilyMapping.fromJson(e)).toList();
  }

  Future<List<ChecklistFamilyMapping>> getMappingByFamilyCode(String codeFamille) async {
    final response = await _dio.get('/admin/checklists/families/$codeFamille');
    return (response.data as List).map((e) => ChecklistFamilyMapping.fromJson(e)).toList();
  }

  Future<ChecklistFamilyMapping> addFamilyToGroup(int groupId, String codeFamille) async {
    final response = await _dio.post('/admin/checklists/groups/$groupId/families', data: {'codeFamille': codeFamille});
    return ChecklistFamilyMapping.fromJson(response.data);
  }

  Future<void> deleteFamilyMapping(int mappingId) async {
    await _dio.delete('/admin/checklists/families/mappings/$mappingId');
  }

  Future<List<ErpFamily>> getErpFamilies() async {
    try {
      final response = await _dio.get('/admin/checklists/erp-families');
      dynamic data = response.data;
      if (data == null) return [];
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List) {
        return data.map((e) => ErpFamily.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ERP families: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getArticles({String? search, int page = 0, int size = 25}) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _dio.get(
      '/admin/checklists/articles',
      queryParameters: params,
    );
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  // ============================================
  // TASK TYPES
  // ============================================
  Future<List<ChecklistTaskType>> getTaskTypes() async {
    final response = await _dio.get('/admin/checklists/types');
    return (response.data as List).map((e) => ChecklistTaskType.fromJson(e)).toList();
  }

  Future<ChecklistTaskType> createTaskType(String name, {String? information}) async {
    final response = await _dio.post('/admin/checklists/types', data: {
      'name': name,
      'information': information,
    });
    return ChecklistTaskType.fromJson(response.data);
  }

  Future<void> deleteTaskType(int id) async {
    await _dio.delete('/admin/checklists/types/$id');
  }

  // ============================================
  // TASKS
  // ============================================
  Future<List<ChecklistTask>> getAllTasks() async {
    final response = await _dio.get('/admin/checklists/tasks');
    return (response.data as List).map((e) => ChecklistTask.fromJson(e)).toList();
  }

  Future<List<ChecklistTask>> getTasksByGroup(int groupId) async {
    final response = await _dio.get('/admin/checklists/groups/$groupId/tasks');
    return (response.data as List).map((e) => ChecklistTask.fromJson(e)).toList();
  }

  Future<ChecklistTask> createTask(int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) async {
    final Map<String, dynamic> params = {'typeId': typeId};
    if (groupId != null) params['groupId'] = groupId;
    if (codeFamille != null && codeFamille.trim().isNotEmpty) params['codeFamille'] = codeFamille;

    final response = await _dio.post(
      '/admin/checklists/tasks',
      queryParameters: params,
      data: {
        'nomTache': nomTache,
        'information': information,
      },
    );
    return ChecklistTask.fromJson(response.data);
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('/admin/checklists/tasks/$id');
  }

  Future<ChecklistTask> toggleTaskActive(int id, bool active) async {
    final response = await _dio.put(
      '/admin/checklists/tasks/$id/active',
      queryParameters: {'active': active},
    );
    return ChecklistTask.fromJson(response.data);
  }

  // ============================================
  // RESPONSES
  // ============================================
  Future<List<ChecklistResponse>> getResponses(String idLigneDocument) async {
    final response = await _dio.get('/checklists/responses/$idLigneDocument');
    return (response.data as List).map((e) => ChecklistResponse.fromJson(e)).toList();
  }

  Future<ChecklistResponse> toggleResponse(String idLigneDocument, int taskId, bool isChecked) async {
    final response = await _dio.post(
      '/checklists/responses/$idLigneDocument',
      queryParameters: {'taskId': taskId, 'isChecked': isChecked},
    );
    return ChecklistResponse.fromJson(response.data);
  }

  Future<ChecklistResponse> saveResponseNote(String idLigneDocument, int taskId, String? note) async {
    final response = await _dio.put(
      '/checklists/responses/$idLigneDocument/note',
      queryParameters: {
        'taskId': taskId,
        if (note != null) 'note': note,
      },
    );
    return ChecklistResponse.fromJson(response.data);
  }

  Future<ChecklistTaskType> updateTaskType(int id, String name, {String? information}) async {
    final response = await _dio.put('/admin/checklists/types/$id', data: {
      'name': name,
      'information': information,
    });
    return ChecklistTaskType.fromJson(response.data);
  }

  Future<ChecklistTask> updateTask(int id, int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) async {
    final Map<String, dynamic> params = {'typeId': typeId};
    if (groupId != null) params['groupId'] = groupId;
    if (codeFamille != null && codeFamille.trim().isNotEmpty) params['codeFamille'] = codeFamille;

    final response = await _dio.put(
      '/admin/checklists/tasks/$id',
      queryParameters: params,
      data: {
        'nomTache': nomTache,
        'information': information,
      },
    );
    return ChecklistTask.fromJson(response.data);
  }
}
