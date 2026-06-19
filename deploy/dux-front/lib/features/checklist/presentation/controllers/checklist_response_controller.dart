import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_models.dart';

// Provider to fetch responses for a given line ID
final checklistResponsesProvider = FutureProvider.family<List<ChecklistResponse>, String>((ref, idLigneDocument) {
  return ref.watch(checklistRepositoryProvider).getResponses(idLigneDocument);
});

final familyMappingByCodeProvider = FutureProvider.family<List<ChecklistFamilyMapping>, String>((ref, codeFamille) {
  if (codeFamille.trim().isEmpty) return [];
  return ref.watch(checklistRepositoryProvider).getMappingByFamilyCode(codeFamille);
});

class ChecklistResponseController extends StateNotifier<AsyncValue<void>> {
  final ChecklistRepository _repository;
  final Ref _ref;

  ChecklistResponseController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> toggleResponse(String idLigneDocument, int taskId, bool isChecked) async {
    // Optimistic update could be implemented here, but for simplicity we just invalidate
    try {
      await _repository.toggleResponse(idLigneDocument, taskId, isChecked);
      _ref.invalidate(checklistResponsesProvider(idLigneDocument));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> saveResponseNote(String idLigneDocument, int taskId, String? note) async {
    try {
      await _repository.saveResponseNote(idLigneDocument, taskId, note);
      _ref.invalidate(checklistResponsesProvider(idLigneDocument));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final checklistResponseControllerProvider = StateNotifierProvider<ChecklistResponseController, AsyncValue<void>>((ref) {
  return ChecklistResponseController(ref.watch(checklistRepositoryProvider), ref);
});
