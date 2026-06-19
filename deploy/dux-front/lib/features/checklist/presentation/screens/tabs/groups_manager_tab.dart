import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import '../../controllers/checklist_admin_controller.dart';
import '../../../domain/models/checklist_models.dart';

class GroupsManagerTab extends ConsumerWidget {
  const GroupsManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Groupe'),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: InfoCard(
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.category_rounded, color: theme.colorScheme.primary),
                      ),
                      title: Text(group.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      children: [
                      _GroupFamiliesList(groupId: group.id!),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppSpacing.s,
                          runSpacing: AppSpacing.s,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showAddFamilyDialog(context, ref, group),
                              icon: const Icon(Icons.add_link_rounded),
                              label: const Text('Associer Famille'),
                            ),
                            TextButton.icon(
                              onPressed: () => ref.read(checklistAdminControllerProvider.notifier).deleteGroup(group.id!),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Supprimer Groupe', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      )
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
          Icon(Icons.category_outlined, size: 64, color: theme.colorScheme.outline),
          AppSpacing.gapM,
          Text('Aucun groupe configuré', style: theme.textTheme.titleMedium),
          AppSpacing.gapS,
          Text('Créez un groupe pour organiser vos familles.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Groupe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom du groupe (ex: Caisse)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(checklistAdminControllerProvider.notifier).createGroup(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showAddFamilyDialog(BuildContext context, WidgetRef ref, ChecklistGroup group) {
    showDialog(
      context: context,
      builder: (context) => _AddFamilyDialog(group: group),
    );
  }
}

class _AddFamilyDialog extends ConsumerStatefulWidget {
  final ChecklistGroup group;
  const _AddFamilyDialog({required this.group});

  @override
  ConsumerState<_AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends ConsumerState<_AddFamilyDialog> {
  String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(erpFamiliesProvider);

    return AlertDialog(
      title: Text('Associer à ${widget.group.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: familiesAsync.when(
          data: (families) {
            final uniqueFamilies = families.fold<Map<String, ErpFamily>>({}, (map, item) {
              if (item.code.isNotEmpty) map[item.code] = item;
              return map;
            }).values.toList();

            uniqueFamilies.sort((a, b) => a.libelle.toLowerCase().compareTo(b.libelle.toLowerCase()));

            if (uniqueFamilies.isEmpty) {
              return const Text('Aucune famille trouvée dans l\'ERP.');
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
                  decoration: const InputDecoration(
                    labelText: 'Famille',
                    hintText: 'Taper pour rechercher...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) {
                      setState(() => selectedCode = null);
                    }
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                // Get the width of the input field to match the dropdown width
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
                setState(() {
                  selectedCode = option.code;
                });
              },
            );
          },
          loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
          error: (e, st) => Text('Erreur: $e'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: selectedCode == null ? null : () {
            ref.read(checklistAdminControllerProvider.notifier).addFamilyToGroup(widget.group.id!, selectedCode!);
            Navigator.pop(context);
          },
          child: const Text('Associer'),
        ),
      ],
    );
  }
}

class _GroupFamiliesList extends ConsumerWidget {
  final int groupId;

  const _GroupFamiliesList({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappingsAsync = ref.watch(familyMappingsProvider(groupId));
    final erpFamiliesAsync = ref.watch(erpFamiliesProvider);
    final theme = Theme.of(context);

    return mappingsAsync.when(
      data: (mappings) {
        if (mappings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Text('Aucune famille associée à ce groupe.'),
          );
        }
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: mappings.map((mapping) {
            String label = mapping.codeFamille;
            erpFamiliesAsync.whenData((families) {
              try {
                final family = families.firstWhere((f) => f.code == mapping.codeFamille);
                if (family.libelle.isNotEmpty) {
                  label = '${mapping.codeFamille} | ${family.libelle}';
                }
              } catch (_) {}
            });

            return Chip(
              label: Text(label),
              onDeleted: () => ref.read(checklistAdminControllerProvider.notifier).deleteFamilyMapping(groupId, mapping.id!),
              deleteIconColor: Colors.redAccent,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Erreur: $e'),
    );
  }
}
