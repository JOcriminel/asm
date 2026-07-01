import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/signature_pad_dialog.dart';
import 'package:dux_front/core/widgets/photo_proof_overlay.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import '../../../../core/widgets/dux_app_bar_title.dart';
import '../../../checklist/domain/models/checklist_models.dart';
import '../../../checklist/presentation/controllers/checklist_admin_controller.dart';
import '../../../checklist/presentation/controllers/checklist_response_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/bon_preparation.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import 'package:dux_front/features/bon_sortie/presentation/controllers/bon_sortie_detail_controller.dart';
import 'package:dux_front/features/command_details/presentation/controllers/command_details_controller.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';

class PreparationChecklistScreen extends ConsumerStatefulWidget {
  final String preparationId;
  final String docType;

  const PreparationChecklistScreen({
    super.key,
    required this.preparationId,
    this.docType = 'BP',
  });

  @override
  ConsumerState<PreparationChecklistScreen> createState() => _PreparationChecklistScreenState();
}

class _PreparationChecklistScreenState extends ConsumerState<PreparationChecklistScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isSaving = false;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showTypeInfoDialog(BuildContext context, ChecklistTaskType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Consignes : ${type.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.information ?? 'Aucune consigne configurée.'),
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

  Future<void> _submitChecklist(String id) async {
    if (_isSaving) return;

    final configState = ref.read(screenConfigControllerProvider);
    final config = configState.configs[widget.docType] ?? configState.configs['BP'];
    final requireSignature = config?.requireSignature ?? false;
    final requirePhoto = config?.requirePhoto ?? false;

    String? signatureBase64;
    if (requireSignature) {
      signatureBase64 = await SignaturePadDialog.show(context);
      if (signatureBase64 == null) return;
    }

    String? photoBase64;
    if (requirePhoto) {
      photoBase64 = await PhotoProofOverlay.show(context);
      if (photoBase64 == null) return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(bonPreparationRepositoryProvider);
      await repository.updateDocumentStatus(id, '12', {
        'signatureBase64': signatureBase64,
        'photoBase64': photoBase64,
        'docType': widget.docType,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Document finalisé et validé avec succès!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      if (widget.docType == 'BP') {
        ref.read(bonPreparationDetailControllerProvider(id).notifier).fetchDetails();
      } else if (widget.docType == 'BS') {
        ref.read(bonSortieDetailControllerProvider(id).notifier).fetchDetails();
      } else {
        ref.read(commandDetailsControllerProvider(id).notifier).fetchDetails();
      }
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docType = widget.docType;
    String documentId = widget.preparationId;
    List<PreparationArticle> articles = [];
    bool isLoading = false;
    String? error;

    if (docType == 'BP' || docType == 'DPR') {
      final state = ref.watch(bonPreparationDetailControllerProvider(documentId));
      isLoading = state.isLoading;
      error = state.error;
      if (state.preparation != null) {
        articles = state.preparation!.articles;
      }
    } else if (docType == 'BS') {
      final state = ref.watch(bonSortieDetailControllerProvider(documentId));
      isLoading = state.isLoading;
      error = state.error;
      if (state.sortie != null) {
        articles = state.sortie!.articles.map((e) => PreparationArticle(
          id: e.id,
          code: e.code,
          name: e.name,
          quantity: e.quantity,
          unitPrice: e.unitPrice,
          unite: e.unite,
          discountPercent: e.discountPercent,
          netHT: e.netHT,
          tvaPercent: e.tvaPercent,
          puTTC: e.puTTC,
          totalTTC: e.totalTTC,
          stock: e.stock,
          serialNumbers: e.serialNumbers,
          rawJson: e.rawJson,
          familyId: e.familyId,
          familyName: e.familyName,
        )).toList();
      }
    } else {
      final state = ref.watch(commandDetailsControllerProvider(documentId));
      isLoading = state.isLoading;
      error = state.error;
      if (state.command != null) {
        articles = state.command!.articles.map((e) => PreparationArticle(
          id: e.id,
          code: e.code,
          name: e.name,
          quantity: e.quantity,
          unitPrice: e.unitPrice,
          unite: e.unite,
          discountPercent: e.discountPercent,
          netHT: e.netHT,
          tvaPercent: e.tvaPercent,
          puTTC: e.puTTC,
          totalTTC: e.totalTTC,
          stock: e.stock,
          serialNumbers: e.serialNumbers,
          rawJson: e.rawJson,
          familyId: e.familyId,
          familyName: e.familyName,
        )).toList();
      }
    }

    final typesAsync = ref.watch(taskTypesProvider);
    final tasksAsync = ref.watch(tasksProvider);

    if (isLoading || typesAsync.isLoading || tasksAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (error != null || typesAsync.hasError || tasksAsync.hasError) {
      final errorMsg = error ?? typesAsync.error?.toString() ?? tasksAsync.error?.toString() ?? 'Erreur inconnue';
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur de chargement:\n$errorMsg',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
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

    var normalizedDocType = widget.docType;
    if (normalizedDocType == 'DPR') normalizedDocType = 'BP';
    final taskTypes = (typesAsync.value ?? [])
        .where((t) => t.active && (t.codeDoc == null || t.codeDoc!.isEmpty || t.codeDoc == normalizedDocType) && matchesRole(t.roles, userRole))
        .toList();
    final allTasks = tasksAsync.value ?? [];

    if (taskTypes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const DuxAppBarTitle(title: 'Checklist')),
        body: const Center(child: Text('Aucun type de tâche configuré.')),
      );
    }

    if (_tabController == null || _tabController!.length != taskTypes.length) {
      _tabController?.dispose();
      _tabController = TabController(length: taskTypes.length, vsync: this);
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Checklist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          tabs: taskTypes.map((t) {
            final hasTypeInfo = t.information != null && t.information!.isNotEmpty;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.name),
                  if (hasTypeInfo) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        _showTypeInfoDialog(context, t);
                      },
                      child: const Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: taskTypes.map((type) {
          return _TypeTabContent(
            type: type,
            articles: articles,
            allTasks: allTasks.where((t) => t.active).toList(),
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
            ),
            onPressed: () => _submitChecklist(documentId),
            child: _isSaving 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'VALIDER LE DOCUMENT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TypeTabContent extends StatelessWidget {
  final ChecklistTaskType type;
  final List<PreparationArticle> articles;
  final List<ChecklistTask> allTasks;

  const _TypeTabContent({
    required this.type,
    required this.articles,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return _ArticleAccordion(
          article: article,
          type: type,
          allTasks: allTasks,
        );
      },
    );
  }
}

class _ArticleAccordion extends ConsumerWidget {
  final PreparationArticle article;
  final ChecklistTaskType type;
  final List<ChecklistTask> allTasks;

  const _ArticleAccordion({
    required this.article,
    required this.type,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = article.familyId ?? '';
    final mappingAsync = ref.watch(familyMappingByCodeProvider(familyId));
    final responsesAsync = ref.watch(checklistResponsesProvider(article.id));
    final theme = Theme.of(context);

    if (mappingAsync.isLoading || responsesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.m),
        child: Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))),
      );
    }

    final mappings = (mappingAsync.value ?? [])
        .where((m) => m.group == null || m.group!.active)
        .toList();
    final group = mappings.isNotEmpty ? mappings.first.group : null;

    final groupTasks = allTasks.where((t) {
      final isCorrectType = t.type?.id == type.id;
      final isGlobal = t.group == null && (t.codeFamille == null || t.codeFamille!.isEmpty);
      final isForGroup = group != null && t.group?.id == group.id;
      final isForFamily = t.codeFamille == familyId;
      return isCorrectType && (isGlobal || isForGroup || isForFamily);
    }).toList();

    if (groupTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final responses = responsesAsync.value ?? [];
    
    int checkedCount = 0;
    for (var t in groupTasks) {
      final isChecked = responses.any((r) => r.task?.id == t.id && r.isChecked);
      if (isChecked) checkedCount++;
    }
    
    final isComplete = checkedCount == groupTasks.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.roundedM,
          side: BorderSide(
            color: isComplete ? Colors.green.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
          )
        ),
        child: ExpansionTile(
          initiallyExpanded: !isComplete,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            article.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isComplete ? Colors.green : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '$checkedCount/${groupTasks.length} cochés',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isComplete ? Colors.green : theme.colorScheme.secondary,
            ),
          ),
          trailing: isComplete 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
          children: groupTasks.map((task) {
            final response = responses.firstWhere(
              (r) => r.task?.id == task.id,
              orElse: () => ChecklistResponse(idLigneDocument: article.id, isChecked: false, task: task)
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
                          ref.read(checklistResponseControllerProvider.notifier).toggleResponse(article.id, task.id!, value);
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
                          onPressed: () => _showNoteDialog(context, ref, article.id, task.id!, response.note),
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
  }

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
}
