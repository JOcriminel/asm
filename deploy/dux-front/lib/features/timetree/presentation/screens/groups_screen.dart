import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';

/// TimeTree Groups CRUD Screen.
///
/// Features:
///   • Refreshable list of groups.
///   • Text filtering/search query.
///   • Switch to toggle group active status.
///   • Create group modal dialog.
///   • Edit group modal dialog.
///   • Delete group confirmation dialog.
class TimetreeGroupsScreen extends ConsumerWidget {
  const TimetreeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(filteredTimetreeGroupsProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('TimeTree – Groupes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search header ──────────────────────────────────────────────────
          const _SearchHeader(),

          // ── Groups List ────────────────────────────────────────────────────
          Expanded(
            child: groupsAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.read(timetreeGroupsProvider.notifier).loadGroups(),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return _GroupsListView(groups: list);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Groupe'),
      ),
    );
  }

  void _showCreateEditDialog(
    BuildContext context,
    WidgetRef ref, {
    TimetreeGroup? group,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _GroupFormDialog(group: group),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Header Component
// ─────────────────────────────────────────────────────────────────────────────

class _SearchHeader extends ConsumerWidget {
  const _SearchHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(timetreeGroupSearchQueryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: TextField(
        onChanged: (val) => ref.read(timetreeGroupSearchQueryProvider.notifier).state = val,
        decoration: InputDecoration(
          hintText: 'Rechercher un groupe…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => ref.read(timetreeGroupSearchQueryProvider.notifier).state = '',
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State Feedbacks (Loading / Error / Empty)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des groupes…'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchActive = ref.read(timetreeGroupSearchQueryProvider).isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              searchActive ? 'Aucun groupe correspondant' : 'Aucun groupe enregistré',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchActive) ...[
              const SizedBox(height: 8),
              Text(
                'Essayez d\'ajuster vos termes de recherche.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success List View
// ─────────────────────────────────────────────────────────────────────────────

class _GroupsListView extends ConsumerWidget {
  const _GroupsListView({required this.groups});

  final List<TimetreeGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(timetreeGroupsProvider.notifier).loadGroups(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _GroupTile(group: group);
        },
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.group});

  final TimetreeGroup group;

  void _handleDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(timetreeGroupsProvider.notifier).deleteGroup(group.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Groupe supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _GroupFormDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: group.active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.people_alt_rounded,
            color: group.active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          group.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                group.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              group.active ? 'Statut : Actif' : 'Statut : Inactif',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: group.active ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: group.active,
              onChanged: (active) async {
                try {
                  await ref
                      .read(timetreeGroupsProvider.notifier)
                      .toggleGroupActivation(group.id, active);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur d\'activation: $e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _handleEdit(context, ref),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _handleDelete(context, ref),
              color: theme.colorScheme.error,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create/Edit Dialog Form
// ─────────────────────────────────────────────────────────────────────────────

class _GroupFormDialog extends ConsumerStatefulWidget {
  const _GroupFormDialog({this.group});

  final TimetreeGroup? group;

  @override
  ConsumerState<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<_GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _active;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _descriptionController = TextEditingController(text: widget.group?.description ?? '');
    _active = widget.group?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (widget.group == null) {
        // Create mode
        await ref.read(timetreeGroupsProvider.notifier).createGroup(
              name: name,
              description: description,
              active: _active,
            );
      } else {
        // Edit mode
        await ref.read(timetreeGroupsProvider.notifier).updateGroup(
              id: widget.group!.id,
              name: name,
              description: description,
              active: _active,
            );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.group == null
                  ? 'Groupe créé avec succès'
                  : 'Groupe modifié avec succès',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.group == null ? 'Ajouter un groupe' : 'Modifier le groupe';

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe',
                  hintText: 'ex. Administrateurs, Vendeurs',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'ex. Membres ayant tous les droits',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Actif'),
                value: _active,
                onChanged: (val) {
                  setState(() {
                    _active = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
