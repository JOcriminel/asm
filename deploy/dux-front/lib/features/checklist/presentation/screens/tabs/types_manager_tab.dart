import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/services/user_roles_provider.dart';
import '../../controllers/checklist_admin_controller.dart';
import '../../../domain/models/checklist_models.dart';

class TypesManagerTab extends ConsumerWidget {
  const TypesManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(taskTypesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTypeDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Type'),
      ),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
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
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.withValues(alpha: 0.1),
                            child: const Icon(Icons.style_rounded, color: Colors.orange),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        type.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (type.codeDoc != null && type.codeDoc!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          type.codeDoc!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (type.information != null && type.information!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      type.information!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (type.roles != null && type.roles!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: type.roles!.map((role) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.blueAccent.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          role,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.blueAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                            tooltip: 'Modifier',
                            onPressed: () => _showEditTypeDialog(context, ref, type),
                          ),
                        ],
                      ),
                      const Divider(height: 16, thickness: 0.5),
                      Row(
                        children: [
                          Text(
                            type.active ? 'Actif (apparaît)' : 'Non (n\'apparaît pas)',
                            style: TextStyle(
                              fontSize: 12,
                              color: type.active ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: type.active,
                            onChanged: (val) {
                              ref.read(checklistAdminControllerProvider.notifier).toggleTaskTypeActive(type.id!, val);
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
          Icon(Icons.style_outlined, size: 64, color: theme.colorScheme.outline),
          AppSpacing.gapM,
          Text('Aucun type de tâche configuré', style: theme.textTheme.titleMedium),
          AppSpacing.gapS,
          Text('Créez des types comme INSTALLATION, TEST, etc.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddTypeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final infoController = TextEditingController();
    final configsState = ref.read(screenConfigControllerProvider);
    final docTypes = configsState.configs.keys.toList();
    String? selectedCodeDoc;
    List<String> selectedRoles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouveau Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du type (ex: TEST)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCodeDoc,
                  decoration: const InputDecoration(
                    labelText: 'Page / Document cible',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Global (Toutes les pages)'),
                    ),
                    ...docTypes.map((type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(configsState.configs[type]?.pageTitle ?? type),
                        )),
                  ],
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedCodeDoc = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: infoController,
                  decoration: const InputDecoration(
                    labelText: 'Informations / Consignes',
                    hintText: 'Ex: Vérifier que la température est correcte',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rôles autorisés (si aucun, visible par tous) :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final rolesAsync = ref.watch(userRolesProvider);
                    return rolesAsync.when(
                      data: (roles) {
                        final uniqueRoles = <String, UserRole>{};
                        for (var r in roles) {
                          uniqueRoles[r.code] = r;
                        }
                        final rolesList = uniqueRoles.values.toList();

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: rolesList.map((role) {
                            final isSelected = selectedRoles.contains(role.code);
                            return FilterChip(
                              label: Text(role.label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  if (selected) {
                                    selectedRoles.add(role.code);
                                  } else {
                                    selectedRoles.remove(role.code);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Erreur lors du chargement des rôles : $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final info = infoController.text.trim();
                  ref.read(checklistAdminControllerProvider.notifier).createTaskType(
                    nameController.text.trim(),
                    information: info.isEmpty ? null : info,
                    codeDoc: selectedCodeDoc,
                    roles: selectedRoles.isEmpty ? null : selectedRoles,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTypeDialog(BuildContext context, WidgetRef ref, ChecklistTaskType type) {
    final nameController = TextEditingController(text: type.name);
    final infoController = TextEditingController(text: type.information);
    final configsState = ref.read(screenConfigControllerProvider);
    final docTypes = configsState.configs.keys.toList();
    String? selectedCodeDoc = type.codeDoc;
    List<String> selectedRoles = List<String>.from(type.roles ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier le Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du type'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCodeDoc,
                  decoration: const InputDecoration(
                    labelText: 'Page / Document cible',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Global (Toutes les pages)'),
                    ),
                    ...docTypes.map((docType) => DropdownMenuItem<String?>(
                          value: docType,
                          child: Text(configsState.configs[docType]?.pageTitle ?? docType),
                        )),
                  ],
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedCodeDoc = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: infoController,
                  decoration: const InputDecoration(labelText: 'Informations / Consignes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rôles autorisés (si aucun, visible par tous) :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final rolesAsync = ref.watch(userRolesProvider);
                    return rolesAsync.when(
                      data: (roles) {
                        final uniqueRoles = <String, UserRole>{};
                        for (var r in roles) {
                          uniqueRoles[r.code] = r;
                        }
                        final rolesList = uniqueRoles.values.toList();

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: rolesList.map((role) {
                            final isSelected = selectedRoles.contains(role.code);
                            return FilterChip(
                              label: Text(role.label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  if (selected) {
                                    selectedRoles.add(role.code);
                                  } else {
                                    selectedRoles.remove(role.code);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Erreur lors du chargement des rôles : $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final info = infoController.text.trim();
                  ref.read(checklistAdminControllerProvider.notifier).updateTaskType(
                    type.id!,
                    nameController.text.trim(),
                    information: info.isEmpty ? null : info,
                    codeDoc: selectedCodeDoc,
                    roles: selectedRoles.isEmpty ? null : selectedRoles,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
