import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import '../../../../core/widgets/dux_app_bar_title.dart';
import '../../../checklist/domain/models/checklist_models.dart';
import '../../../checklist/presentation/controllers/checklist_admin_controller.dart';
import '../../../checklist/presentation/controllers/checklist_response_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/bon_preparation.dart';

class ArticleChecklistScreen extends ConsumerStatefulWidget {
  final String preparationId;
  final PreparationArticle article;
  final String docType;

  const ArticleChecklistScreen({
    super.key,
    required this.preparationId,
    required this.article,
    this.docType = 'BP',
  });

  @override
  ConsumerState<ArticleChecklistScreen> createState() => _ArticleChecklistScreenState();
}

class _ArticleChecklistScreenState extends ConsumerState<ArticleChecklistScreen> {

  void _showInfoDialog(BuildContext context, ChecklistTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Informations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.nomTache,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 24),
              if (task.information != null && task.information!.isNotEmpty) ...[
                const Text('Consignes de la tâche :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.information!),
                const SizedBox(height: 16),
              ],
              if (task.type?.information != null && task.type!.information!.isNotEmpty) ...[
                Text('Consignes du type (${task.type!.name}) :', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.type!.information!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, String idLigneDocument, int taskId, String? currentNote) {
    final controller = TextEditingController(text: currentNote ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.note_alt_outlined, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Note de la tâche', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Saisissez votre note ici...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Annuler'),
          ),
          if (currentNote != null && currentNote.trim().isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(checklistResponseControllerProvider.notifier).saveResponseNote(idLigneDocument, taskId, null);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ElevatedButton(
            onPressed: () {
              final note = controller.text.trim();
              ref.read(checklistResponseControllerProvider.notifier).saveResponseNote(
                idLigneDocument,
                taskId,
                note.isEmpty ? null : note,
              );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog(BuildContext context, ChecklistResponse response, ChecklistTask task) {
    final theme = Theme.of(context);
    String formatDateTime(String? isoString) {
      if (isoString == null) return 'N/A';
      try {
        final dt = DateTime.parse(isoString);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return isoString;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.history_toggle_off_outlined, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            const Text('Logs de validation', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tâche : ${task.nomTache}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    response.isChecked ? Icons.check_circle_outline : Icons.radio_button_off,
                    color: response.isChecked ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response.isChecked ? 'Validée' : 'Non validée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: response.isChecked ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (response.isChecked) ...[
                          const SizedBox(height: 2),
                          Text('Par : ${response.checkedBy ?? 'Inconnu'}', style: theme.textTheme.bodySmall),
                          Text('Le : ${formatDateTime(response.dateChecked)}', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    color: (response.note != null && response.note!.isNotEmpty) ? Colors.blueAccent : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note / Commentaire',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (response.note != null && response.note!.isNotEmpty) ? Colors.blueAccent : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (response.note != null && response.note!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              response.note!,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Par : ${response.checkedBy ?? 'Inconnu'}', style: theme.textTheme.bodySmall),
                          Text('Écrit le : ${formatDateTime(response.dateNote)}', style: theme.textTheme.bodySmall),
                        ] else
                          const Text('Aucune note enregistrée', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(taskTypesProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final familyId = widget.article.familyId ?? '';
    final mappingAsync = ref.watch(familyMappingByCodeProvider(familyId));
    final responsesAsync = ref.watch(checklistResponsesProvider(widget.article.id));

    final theme = Theme.of(context);

    if (typesAsync.isLoading || tasksAsync.isLoading || mappingAsync.isLoading || responsesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (typesAsync.hasError || tasksAsync.hasError || mappingAsync.hasError || responsesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const DuxAppBarTitle(title: 'Checklist Article'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Erreur de chargement de la checklist.')),
      );
    }

    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role;

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

    var docType = widget.docType;
    if (docType == 'DPR') docType = 'BP';

    final taskTypes = (typesAsync.value ?? [])
        .where((t) => t.active && (t.codeDoc == null || t.codeDoc!.isEmpty || t.codeDoc == docType) && matchesRole(t.roles, userRole))
        .toList();
    final allTasks = (tasksAsync.value ?? []).where((t) => t.active).toList();
    final mappings = (mappingAsync.value ?? [])
        .where((m) => m.group == null || m.group!.active)
        .toList();
    final group = mappings.isNotEmpty ? mappings.first.group : null;
    final responses = responsesAsync.value ?? [];

    final filteredTypes = taskTypes.where((type) {
      final groupTasks = allTasks.where((t) {
        final isCorrectType = t.type?.id == type.id;
        final isGlobal = t.group == null && (t.codeFamille == null || t.codeFamille!.isEmpty);
        final isForGroup = group != null && t.group?.id == group.id;
        final isForFamily = t.codeFamille == familyId;
        return isCorrectType && (isGlobal || isForGroup || isForFamily);
      }).toList();
      return groupTasks.isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Checklist Article'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Article Name Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.l),
              margin: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.name.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 14, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Code: ${widget.article.code}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                      ),
                      if (widget.article.familyName != null && widget.article.familyName!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.category_outlined, size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Famille: ${widget.article.familyName}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            if (filteredTypes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('Aucune tâche configurée pour cet article.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                itemCount: filteredTypes.length,
                itemBuilder: (context, index) {
                  final type = filteredTypes[index];
                  
                  final groupTasks = allTasks.where((t) {
                    final isCorrectType = t.type?.id == type.id;
                    final isGlobal = t.group == null && (t.codeFamille == null || t.codeFamille!.isEmpty);
                    final isForGroup = group != null && t.group?.id == group.id;
                    final isForFamily = t.codeFamille == familyId;
                    return isCorrectType && (isGlobal || isForGroup || isForFamily);
                  }).toList();

                  int typeCheckedCount = 0;
                  for (var t in groupTasks) {
                    final isChecked = responses.any((r) => r.task?.id == t.id && r.isChecked);
                    if (isChecked) typeCheckedCount++;
                  }
                  
                  final isTypeComplete = typeCheckedCount == groupTasks.length;
                  
                  // Color matching logic for type accordion subtitle/border
                  Color stateColor;
                  if (typeCheckedCount == 0) {
                    stateColor = Colors.red.shade700;
                  } else if (isTypeComplete) {
                    stateColor = Colors.green.shade700;
                  } else {
                    stateColor = Colors.orange.shade700;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.roundedM,
                        side: BorderSide(
                          color: isTypeComplete ? Colors.green.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: !isTypeComplete,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          type.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTypeComplete ? Colors.green : theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '$typeCheckedCount/${groupTasks.length} cochés',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: stateColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: isTypeComplete 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.keyboard_arrow_down, color: stateColor),
                        children: groupTasks.map((task) {
                          final response = responses.firstWhere(
                            (r) => r.task?.id == task.id,
                            orElse: () => ChecklistResponse(idLigneDocument: widget.article.id, isChecked: false, task: task)
                          );
                
                          final hasInfo = (task.information != null && task.information!.isNotEmpty) ||
                                          (task.type?.information != null && task.type!.information!.isNotEmpty);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: response.isChecked 
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.08) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: response.isChecked
                                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: response.isChecked,
                                    activeColor: theme.colorScheme.primary,
                                    onChanged: (bool? value) {
                                      if (value != null) {
                                        ref.read(checklistResponseControllerProvider.notifier).toggleResponse(widget.article.id, task.id!, value);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.nomTache,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: response.isChecked 
                                                ? theme.colorScheme.onSurface.withValues(alpha: 0.5) 
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (response.note != null && response.note!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.sticky_note_2_outlined, size: 14, color: Colors.blueAccent.shade700),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  response.note!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.blueAccent.shade700,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.note_alt_outlined,
                                          size: 20,
                                          color: (response.note != null && response.note!.trim().isNotEmpty)
                                              ? Colors.blueAccent.shade700
                                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                        tooltip: 'Note',
                                        onPressed: () => _showNoteDialog(context, ref, widget.article.id, task.id!, response.note),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                        splashRadius: 20,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.history_toggle_off_outlined,
                                          size: 20,
                                          color: response.isChecked 
                                              ? Colors.green.shade700 
                                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                        tooltip: 'Logs',
                                        onPressed: () => _showLogsDialog(context, response, task),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                        splashRadius: 20,
                                      ),
                                      if (hasInfo)
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, size: 20, color: Colors.blueAccent),
                                          tooltip: 'Informations',
                                          onPressed: () => _showInfoDialog(context, task),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          splashRadius: 20,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
