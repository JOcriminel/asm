import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import '../../controllers/checklist_admin_controller.dart';
import '../../../domain/models/checklist_models.dart';

class TasksManagerTab extends ConsumerWidget {
  const TasksManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Tâche'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final item = tasks[index];
               return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: InfoCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                              child: Icon(Icons.task_alt_rounded, color: theme.colorScheme.secondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nomTache,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (item.group != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item.group!.name,
                                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    else if (item.codeFamille != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Famille: ${item.codeFamille}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSecondaryContainer,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (item.type != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Text(
                                          '${item.type!.name}${item.type!.codeDoc != null && item.type!.codeDoc!.isNotEmpty ? ' (${item.type!.codeDoc})' : ' (Global)'}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.information != null && item.information!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.information!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                            tooltip: 'Modifier',
                            onPressed: () => _showEditTaskDialog(context, ref, item),
                          ),
                        ],
                      ),
                      const Divider(height: 16, thickness: 0.5),
                      Row(
                        children: [
                          Text(
                            item.active ? 'Actif (apparaît)' : 'Non (n\'apparaît pas)',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.active ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: item.active,
                            onChanged: (val) {
                              ref.read(checklistAdminControllerProvider.notifier).toggleTaskActive(item.id!, val);
                            },
                            activeThumbColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl_outlined, size: 64, color: theme.colorScheme.outline),
          AppSpacing.gapM,
          Text('Aucune tâche enregistrée.', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    // Await the futures to ensure data is loaded before opening the dialog
    final groups = await ref.read(groupsProvider.future);
    final types = await ref.read(taskTypesProvider.future);

    if (!context.mounted) return;

    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord créer au moins un type de tâche.')),
      );
      return;
    }

    String targetType = 'group'; // 'group' or 'family'
    ChecklistGroup? selectedGroup = groups.isNotEmpty ? groups.first : null;
    ChecklistTaskType? selectedType = types.first;
    String? selectedFamilyCode;
    final nameController = TextEditingController();
    final infoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_task_rounded, color: Colors.blueAccent),
                SizedBox(width: 10),
                Expanded(child: Text('Nouvelle Tâche', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: targetType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: const [
                      DropdownMenuItem(value: 'group', child: Text('Affecter à un Groupe')),
                      DropdownMenuItem(value: 'family', child: Text('Affecter à une Famille', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setDialogState(() => targetType = val!),
                    decoration: InputDecoration(
                      labelText: 'Cible',
                      prefixIcon: const Icon(Icons.track_changes_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (targetType == 'group') ...[
                    if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text('Aucun groupe disponible.', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      )
                    else
                      DropdownButtonFormField<ChecklistGroup>(
                        initialValue: selectedGroup,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: groups.map((g) => DropdownMenuItem(
                          value: g, 
                          child: Text(g.name, overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedGroup = val),
                        decoration: InputDecoration(
                          labelText: 'Sélectionner le Groupe',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    if (selectedGroup != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final familiesAsync = ref.watch(familyMappingsProvider(selectedGroup!.id!));
                            return familiesAsync.when(
                              data: (mappings) {
                                if (mappings.isEmpty) return const Text('Aucune famille dans ce groupe', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic));
                                final codes = mappings.map((m) => m.codeFamille).join(', ');
                                return Text('Inclus: $codes', style: const TextStyle(fontSize: 12, color: Colors.grey));
                              },
                              loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (_, _) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                  ] else ...[
                    Consumer(
                      builder: (context, ref, child) {
                        final familiesAsync = ref.watch(erpFamiliesProvider);
                        return familiesAsync.when(
                          data: (families) {
                            final uniqueFamilies = families.fold<Map<String, ErpFamily>>({}, (map, item) {
                              if (item.code.isNotEmpty) map[item.code] = item;
                              return map;
                            }).values.toList();

                            uniqueFamilies.sort((a, b) => a.libelle.toLowerCase().compareTo(b.libelle.toLowerCase()));

                            if (uniqueFamilies.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Text('Aucune famille trouvée dans l\'ERP.', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                              );
                            }
                            return Autocomplete<ErpFamily>(
                              displayStringForOption: (option) => '${option.code} | ${option.libelle}',
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final query = textEditingValue.text.toLowerCase();
                                final filtered = query.isEmpty 
                                    ? uniqueFamilies 
                                    : uniqueFamilies.where((f) {
                                        return f.code.toLowerCase().contains(query) || 
                                               f.libelle.toLowerCase().contains(query);
                                      });
                                return filtered.take(25);
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Famille Spécifique',
                                    hintText: 'Rechercher une famille...',
                                    prefixIcon: const Icon(Icons.category_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (val.isEmpty) {
                                      setDialogState(() => selectedFamilyCode = null);
                                    }
                                  },
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                final box = context.findRenderObject() as RenderBox?;
                                final width = box?.size.width ?? 300.0;
                                
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: width,
                                        maxHeight: 250,
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            leading: const Icon(Icons.category_outlined, size: 20),
                                            title: Text('${option.code} | ${option.libelle}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (option) {
                                setDialogState(() {
                                  selectedFamilyCode = option.code;
                                });
                              },
                            );
                          },
                          loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                          error: (e, st) => Text('Erreur: $e'),
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  DropdownButtonFormField<ChecklistTaskType>(
                    initialValue: selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: types.map((t) {
                      final scope = t.codeDoc != null && t.codeDoc!.isNotEmpty ? ' (${t.codeDoc})' : ' (Global)';
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.name}$scope'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val),
                    decoration: InputDecoration(
                      labelText: 'Type de Tâche',
                      prefixIcon: const Icon(Icons.task_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la Tâche',
                      hintText: 'Ex: Vérifier le nettoyage',
                      prefixIcon: const Icon(Icons.text_fields_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: infoController,
                    decoration: InputDecoration(
                      labelText: 'Informations / Consignes (Optionnel)',
                      hintText: 'Ex: S\'assurer que les ports USB sont fonctionnels',
                      prefixIcon: const Icon(Icons.info_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (nameController.text.isEmpty || selectedType == null) return;
                  
                  int? groupId;
                  String? codeFamille;
                  
                  if (targetType == 'group') {
                    if (selectedGroup == null) return;
                    groupId = selectedGroup!.id;
                  } else {
                    if (selectedFamilyCode == null) return;
                    codeFamille = selectedFamilyCode;
                  }

                  final info = infoController.text.trim();
                  ref.read(checklistAdminControllerProvider.notifier).createTask(
                    groupId,
                    codeFamille,
                    selectedType!.id!,
                    nameController.text.trim(),
                    information: info.isEmpty ? null : info,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Créer'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, ChecklistTask task) async {
    final groups = await ref.read(groupsProvider.future);
    final types = await ref.read(taskTypesProvider.future);

    if (!context.mounted) return;

    if (types.isEmpty) return;

    String targetType = task.group != null ? 'group' : 'family';
    ChecklistGroup? selectedGroup = task.group ?? (groups.isNotEmpty ? groups.first : null);
    ChecklistTaskType? selectedType = types.firstWhere((t) => t.id == task.type?.id, orElse: () => types.first);
    String? selectedFamilyCode = task.codeFamille;
    final nameController = TextEditingController(text: task.nomTache);
    final infoController = TextEditingController(text: task.information);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                SizedBox(width: 10),
                Expanded(child: Text('Modifier la Tâche', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: targetType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: const [
                      DropdownMenuItem(value: 'group', child: Text('Affecter à un Groupe')),
                      DropdownMenuItem(value: 'family', child: Text('Affecter à une Famille', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setDialogState(() => targetType = val!),
                    decoration: InputDecoration(
                      labelText: 'Cible',
                      prefixIcon: const Icon(Icons.track_changes_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (targetType == 'group') ...[
                    if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text('Aucun groupe disponible.', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      )
                    else
                      DropdownButtonFormField<ChecklistGroup>(
                        initialValue: selectedGroup,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: groups.map((g) => DropdownMenuItem(
                          value: g, 
                          child: Text(g.name, overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedGroup = val),
                        decoration: InputDecoration(
                          labelText: 'Sélectionner le Groupe',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ] else ...[
                    Consumer(
                      builder: (context, ref, child) {
                        final familiesAsync = ref.watch(erpFamiliesProvider);
                        return familiesAsync.when(
                          data: (families) {
                            final uniqueFamilies = families.fold<Map<String, ErpFamily>>({}, (map, item) {
                              if (item.code.isNotEmpty) map[item.code] = item;
                              return map;
                            }).values.toList();

                            uniqueFamilies.sort((a, b) => a.libelle.toLowerCase().compareTo(b.libelle.toLowerCase()));

                            if (uniqueFamilies.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Text('Aucune famille trouvée.', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                              );
                            }
                            return Autocomplete<ErpFamily>(
                              initialValue: TextEditingValue(text: selectedFamilyCode ?? ''),
                              displayStringForOption: (option) => '${option.code} | ${option.libelle}',
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final query = textEditingValue.text.toLowerCase();
                                final filtered = query.isEmpty 
                                    ? uniqueFamilies 
                                    : uniqueFamilies.where((f) {
                                        return f.code.toLowerCase().contains(query) || 
                                               f.libelle.toLowerCase().contains(query);
                                      });
                                return filtered.take(25);
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Famille Spécifique',
                                    hintText: 'Rechercher une famille...',
                                    prefixIcon: const Icon(Icons.category_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (val.isEmpty) {
                                      setDialogState(() => selectedFamilyCode = null);
                                    }
                                  },
                                );
                              },
                              onSelected: (option) {
                                setDialogState(() {
                                  selectedFamilyCode = option.code;
                                });
                              },
                            );
                          },
                          loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                          error: (e, st) => Text('Erreur: $e'),
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  DropdownButtonFormField<ChecklistTaskType>(
                    initialValue: selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: types.map((t) {
                      final scope = t.codeDoc != null && t.codeDoc!.isNotEmpty ? ' (${t.codeDoc})' : ' (Global)';
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.name}$scope'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val),
                    decoration: InputDecoration(
                      labelText: 'Type de Tâche',
                      prefixIcon: const Icon(Icons.task_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la Tâche',
                      hintText: 'Ex: Vérifier le nettoyage',
                      prefixIcon: const Icon(Icons.text_fields_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: infoController,
                    decoration: InputDecoration(
                      labelText: 'Informations / Consignes',
                      hintText: 'Ex: Consigne...',
                      prefixIcon: const Icon(Icons.info_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (nameController.text.isEmpty || selectedType == null) return;
                  
                  int? groupId;
                  String? codeFamille;
                  
                  if (targetType == 'group') {
                    if (selectedGroup == null) return;
                    groupId = selectedGroup!.id;
                  } else {
                    if (selectedFamilyCode == null) return;
                    codeFamille = selectedFamilyCode;
                  }

                  final info = infoController.text.trim();
                  ref.read(checklistAdminControllerProvider.notifier).updateTask(
                    task.id!,
                    groupId,
                    codeFamille,
                    selectedType!.id!,
                    nameController.text.trim(),
                    information: info.isEmpty ? null : info,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Enregistrer'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
