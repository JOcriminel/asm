import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/checklist_api_service.dart';
import '../../domain/models/checklist_models.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.watch(checklistApiServiceProvider));
});

class ChecklistRepository {
  final ChecklistApiService _apiService;

  ChecklistRepository(this._apiService);

  Future<List<ChecklistGroup>> getGroups() => _apiService.getGroups();
  Future<ChecklistGroup> createGroup(String name) => _apiService.createGroup(name);
  Future<void> deleteGroup(int id) => _apiService.deleteGroup(id);

  Future<List<ChecklistFamilyMapping>> getFamiliesByGroup(int groupId) => _apiService.getFamiliesByGroup(groupId);
  Future<List<ChecklistFamilyMapping>> getMappingByFamilyCode(String codeFamille) => _apiService.getMappingByFamilyCode(codeFamille);
  Future<ChecklistFamilyMapping> addFamilyToGroup(int groupId, String codeFamille) => _apiService.addFamilyToGroup(groupId, codeFamille);
  Future<void> deleteFamilyMapping(int id) => _apiService.deleteFamilyMapping(id);
  Future<List<ErpFamily>> getErpFamilies() => _apiService.getErpFamilies();
  Future<List<Map<String, dynamic>>> getArticles({String? search, int page = 0, int size = 25}) => _apiService.getArticles(search: search, page: page, size: size);

  Future<List<ChecklistTaskType>> getTaskTypes() => _apiService.getTaskTypes();
  Future<ChecklistTaskType> createTaskType(String name, {String? information, String? codeDoc, List<String>? roles}) => _apiService.createTaskType(name, information: information, codeDoc: codeDoc, roles: roles);
  Future<void> deleteTaskType(int id) => _apiService.deleteTaskType(id);

  Future<List<ChecklistTask>> getAllTasks() => _apiService.getAllTasks();
  Future<List<ChecklistTask>> getTasksByGroup(int groupId) => _apiService.getTasksByGroup(groupId);
  Future<ChecklistTask> createTask(int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) => _apiService.createTask(groupId, codeFamille, typeId, nomTache, information: information);
  Future<void> deleteTask(int id) => _apiService.deleteTask(id);
  Future<ChecklistTask> toggleTaskActive(int id, bool active) => _apiService.toggleTaskActive(id, active);

  Future<List<ChecklistResponse>> getResponses(String idLigneDocument) => _apiService.getResponses(idLigneDocument);
  Future<ChecklistResponse> toggleResponse(String idLigneDocument, int taskId, bool isChecked) => _apiService.toggleResponse(idLigneDocument, taskId, isChecked);
  Future<ChecklistResponse> saveResponseNote(String idLigneDocument, int taskId, String? note) => _apiService.saveResponseNote(idLigneDocument, taskId, note);

  Future<ChecklistTaskType> updateTaskType(int id, String name, {String? information, String? codeDoc, List<String>? roles}) => _apiService.updateTaskType(id, name, information: information, codeDoc: codeDoc, roles: roles);
  Future<ChecklistTask> updateTask(int id, int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) => _apiService.updateTask(id, groupId, codeFamille, typeId, nomTache, information: information);
  Future<ChecklistGroup> toggleGroupActive(int id, bool active) => _apiService.toggleGroupActive(id, active);
  Future<ChecklistTaskType> toggleTaskTypeActive(int id, bool active) => _apiService.toggleTaskTypeActive(id, active);
}
