import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
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
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: const Icon(Icons.style_rounded, color: Colors.orange),
                    ),
                    title: Text(type.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: (type.information != null && type.information!.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              type.information!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          tooltip: 'Modifier',
                          onPressed: () => _showEditTypeDialog(context, ref, type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: () => ref.read(checklistAdminControllerProvider.notifier).deleteTaskType(type.id!),
                        ),
                      ],
                    ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du type (ex: TEST)'),
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
          ],
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
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditTypeDialog(BuildContext context, WidgetRef ref, ChecklistTaskType type) {
    final nameController = TextEditingController(text: type.name);
    final infoController = TextEditingController(text: type.information);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: infoController,
              decoration: const InputDecoration(labelText: 'Informations / Consignes'),
              maxLines: 3,
            ),
          ],
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
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
