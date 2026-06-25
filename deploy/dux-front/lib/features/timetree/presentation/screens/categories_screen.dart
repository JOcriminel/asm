import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_categories_provider.dart';

/// TimeTree Categories CRUD Screen.
///
/// Features:
///   • Paginated-style/refreshable categories list.
///   • Text filtering/search query.
///   • Switch to toggle category active status (PATCH /activate /deactivate).
///   • Create category modal dialog (POST).
///   • Edit category modal dialog (PUT).
///   • Delete category confirmation dialog (DELETE).
class TimetreeCategoriesScreen extends ConsumerWidget {
  const TimetreeCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(filteredTimetreeCategoriesProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Dux Calender – Catégories'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search & Filter header ─────────────────────────────────────────
          const _SearchHeader(),

          // ── Categories List ────────────────────────────────────────────────
          Expanded(
            child: categoriesAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.read(timetreeCategoriesProvider.notifier).loadCategories(),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return _CategoriesListView(categories: list);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catégorie'),
      ),
    );
  }

  // Helper to open creation/edition modal
  void _showCreateEditDialog(
    BuildContext context,
    WidgetRef ref, {
    TimetreeCategory? category,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
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
    final query = ref.watch(timetreeCategorySearchQueryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: TextField(
        onChanged: (val) => ref.read(timetreeCategorySearchQueryProvider.notifier).state = val,
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => ref.read(timetreeCategorySearchQueryProvider.notifier).state = '',
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
          Text('Chargement des catégories…'),
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
    final searchActive = ref.read(timetreeCategorySearchQueryProvider).isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive ? Icons.search_off_rounded : Icons.category_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              searchActive ? 'Aucune catégorie correspondante' : 'Aucune catégorie enregistrée',
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

class _CategoriesListView extends ConsumerWidget {
  const _CategoriesListView({required this.categories});

  final List<TimetreeCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(timetreeCategoriesProvider.notifier).loadCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryTile(category: cat);
        },
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final TimetreeCategory category;

  void _handleDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(timetreeCategoriesProvider.notifier).deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catégorie supprimée avec succès')),
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
      builder: (context) => _CategoryFormDialog(category: category),
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
          backgroundColor: category.active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.folder_outlined,
            color: category.active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Ordre d\'affichage : ${category.displayOrder}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch for active/inactive status toggle
            Switch(
              value: category.active,
              onChanged: (active) async {
                try {
                  await ref
                      .read(timetreeCategoriesProvider.notifier)
                      .toggleCategoryActivation(category.id, active);
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

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.category});

  final TimetreeCategory? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _orderController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _orderController = TextEditingController(
      text: widget.category != null ? '${widget.category!.displayOrder}' : '1',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final name = _nameController.text.trim();
    final order = int.tryParse(_orderController.text) ?? 1;

    try {
      if (widget.category == null) {
        // Create mode
        await ref.read(timetreeCategoriesProvider.notifier).createCategory(name, order);
      } else {
        // Edit mode
        await ref
            .read(timetreeCategoriesProvider.notifier)
            .updateCategory(widget.category!.id, name, order);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Catégorie créée avec succès'
                  : 'Catégorie modifiée avec succès',
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
    final title = widget.category == null ? 'Ajouter une catégorie' : 'Modifier la catégorie';

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie',
                hintText: 'ex. Finance, Ventes',
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
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Ordre d\'affichage',
                hintText: 'ex. 1, 2, 3',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Veuillez saisir un ordre';
                }
                if (int.tryParse(val) == null) {
                  return 'Veuillez saisir un nombre valide';
                }
                return null;
              },
            ),
          ],
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
