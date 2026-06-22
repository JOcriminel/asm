import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_models.dart';
import '../../../bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import '../../../bon_preparation/domain/models/bon_preparation.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/screen_config_controller.dart';
import 'checklist_admin_controller.dart';

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

class DocumentChecklistCount {
  final int checked;
  final int total;

  const DocumentChecklistCount({required this.checked, required this.total});

  bool get isComplete => checked == total && total > 0;
}

final bonPreparationDetailsProvider = FutureProvider.family<BonPreparation, String>((ref, id) async {
  final repo = ref.watch(bonPreparationRepositoryProvider);
  int retries = 3;
  while (retries > 0) {
    try {
      return await repo.getBonPreparationDetails(id);
    } catch (e) {
      retries--;
      if (retries == 0) rethrow;
      await Future.delayed(Duration(milliseconds: 300 * (4 - retries)));
    }
  }
  throw Exception('Failed to load details');
});

final documentChecklistCountProvider = Provider.family<AsyncValue<DocumentChecklistCount>, String>((ref, param) {
  final parts = param.split(':');
  final documentId = parts[0];
  var docType = parts.length > 1 ? parts[1] : 'BP';
  if (docType == 'DPR') docType = 'BP';

  final configsState = ref.watch(screenConfigControllerProvider);
  final config = configsState.configs[docType];
  final isChecklistEnabled = config?.enableChecklistTracking ?? false;
  if (!isChecklistEnabled) {
    return const AsyncData(DocumentChecklistCount(checked: 0, total: 0));
  }

  if (documentId.isEmpty) {
    return const AsyncData(DocumentChecklistCount(checked: 0, total: 0));
  }

  // 1. Watch the preparation details (registers dependency synchronously)
  final preparationAsync = ref.watch(bonPreparationDetailsProvider(documentId));
  
  return preparationAsync.when(
    data: (preparation) {
      final articles = preparation.articles;
      
      // 2. Watch article counts synchronously for all articles in the preparation
      final articleCounts = articles.map((article) {
        final familyId = article.familyId ?? '';
        return ref.watch(articleChecklistCountProvider('${article.id}:$familyId:$docType'));
      }).toList();

      // Check if any of the article counts are still loading
      final anyLoading = articleCounts.any((c) => c.isLoading);
      if (anyLoading) {
        return const AsyncLoading();
      }

      // Check if there is an error in any count
      final errorState = articleCounts.firstWhere(
        (c) => c.hasError,
        orElse: () => const AsyncData(DocumentChecklistCount(checked: 0, total: 0)),
      );
      if (errorState.hasError) {
        return AsyncError(errorState.error!, errorState.stackTrace!);
      }

      // Accumulate totals
      int totalChecked = 0;
      int totalTasks = 0;

      for (final countVal in articleCounts) {
        final count = countVal.value!;
        totalChecked += count.checked;
        totalTasks += count.total;
      }

      return AsyncData(DocumentChecklistCount(checked: totalChecked, total: totalTasks));
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
  );
});

final articleChecklistCountProvider = FutureProvider.family<DocumentChecklistCount, String>((ref, param) async {
  try {
    final parts = param.split(':');
    final articleId = parts[0];
    final familyId = parts.length > 1 ? parts[1] : '';
    var docType = parts.length > 2 ? parts[2] : 'BP';
    if (docType == 'DPR') docType = 'BP';

    final configsState = ref.watch(screenConfigControllerProvider);
    final config = configsState.configs[docType];
    final isChecklistEnabled = config?.enableChecklistTracking ?? false;
    if (!isChecklistEnabled) {
      return const DocumentChecklistCount(checked: 0, total: 0);
    }

    if (articleId.isEmpty) {
      return const DocumentChecklistCount(checked: 0, total: 0);
    }

    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role;

    // 1. Watch configurations, mapping and responses synchronously at start to register dependencies properly
    final taskTypesFuture = ref.watch(taskTypesProvider.future);
    final allTasksFuture = ref.watch(tasksProvider.future);
    
    // Safely default mapping and responses to empty lists if endpoint fails (e.g. 404/unmapped)
    final mappingFuture = familyId.trim().isNotEmpty
        ? ref.watch(familyMappingByCodeProvider(familyId).future).catchError((_) => <ChecklistFamilyMapping>[])
        : Future.value(<ChecklistFamilyMapping>[]);
        
    final responsesFuture = ref.watch(checklistResponsesProvider(articleId).future).catchError((_) => <ChecklistResponse>[]);

    // 2. Await all futures concurrently
    final results = await Future.wait([
      taskTypesFuture,
      allTasksFuture,
      mappingFuture,
      responsesFuture,
    ]);

    final taskTypes = results[0] as List<ChecklistTaskType>;
    final allTasks = results[1] as List<ChecklistTask>;
    final mappings = results[2] as List<ChecklistFamilyMapping>;
    final responses = results[3] as List<ChecklistResponse>;

    bool matchesRole(List<String>? taskTypeRoles, String? userRole) {
      if (taskTypeRoles == null || taskTypeRoles.isEmpty) {
        return true;
      }
      if (userRole == null || userRole.trim().isEmpty) {
        return false;
      }
      
      String normalize(String r) {
        final lower = r.trim().toLowerCase();
        if (lower == 'admin' || lower == 'administrateur') return 'admin';
        if (lower == 'commercial') return 'commercial';
        if (lower == 'operateur' || lower == 'opérateur') return 'operator';
        return lower;
      }

      final normalizedUser = normalize(userRole);
      return taskTypeRoles.any((r) => normalize(r) == normalizedUser);
    }

    final activeTypes = taskTypes
        .where((t) => t.active && (t.codeDoc == null || t.codeDoc!.isEmpty || t.codeDoc == docType) && matchesRole(t.roles, userRole))
        .toList();
    final activeTasks = allTasks.where((t) => t.active).toList();

    final activeMappings = mappings.where((m) => m.group == null || m.group!.active).toList();
    final group = activeMappings.isNotEmpty ? activeMappings.first.group : null;

    int totalChecked = 0;
    int totalTasksCount = 0;

    for (final type in activeTypes) {
      final groupTasks = activeTasks.where((t) {
        final isCorrectType = t.type?.id == type.id;
        final isGlobal = t.group == null && (t.codeFamille == null || t.codeFamille!.isEmpty);
        final isForGroup = group != null && t.group?.id == group.id;
        final isForFamily = t.codeFamille == familyId;
        return isCorrectType && (isGlobal || isForGroup || isForFamily);
      }).toList();

      totalTasksCount += groupTasks.length;
      for (var t in groupTasks) {
        final isChecked = responses.any((r) => r.task?.id == t.id && r.isChecked);
        if (isChecked) totalChecked++;
      }
    }

    return DocumentChecklistCount(checked: totalChecked, total: totalTasksCount);
  } catch (e, stack) {
    debugPrint('Error calculating article checklist count: $e\n$stack');
    return const DocumentChecklistCount(checked: 0, total: 0);
  }
});
