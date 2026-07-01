import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_page.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_categories_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_pages_provider.dart';

/// TimeTree Pages CRUD Screen.
///
/// Features:
///   • Refreshable list of pages.
///   • Text filtering/search query.
///   • Category selection filter (drop-down at top).
///   • Switch to toggle active status.
///   • Display associated Category name per Page card (from Categories Provider).
///   • Create Page modal (with Category dropdown).
///   • Edit Page modal (with Category dropdown).
///   • Delete Page confirmation modal.
class TimetreePagesScreen extends ConsumerWidget {
  const TimetreePagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(filteredTimetreePagesProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Dux Calender – Pages'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search & Filter header ─────────────────────────────────────────
          const _SearchAndFilterHeader(),

          // ── Pages List ─────────────────────────────────────────────────────
          Expanded(
            child: pagesAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.read(timetreePagesProvider.notifier).loadPages(),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return _PagesListView(pages: list);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEditDialog(
    BuildContext context,
    WidgetRef ref, {
    TimetreePage? page,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _PageFormDialog(page: page),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search and Category Filter Header Component
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAndFilterHeader extends ConsumerWidget {
  const _SearchAndFilterHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(timetreePageSearchQueryProvider);
    final selectedCatId = ref.watch(timetreePageCategoryFilterProvider);
    final categoriesAsync = ref.watch(timetreeCategoriesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Search box
          TextField(
            onChanged: (val) => ref.read(timetreePageSearchQueryProvider.notifier).state = val,
            decoration: InputDecoration(
              hintText: 'Rechercher une page…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => ref.read(timetreePageSearchQueryProvider.notifier).state = '',
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
          const SizedBox(height: 12),

          // Category filter dropdown
          categoriesAsync.when(
            data: (cats) {
              return DropdownButtonFormField<String?>(
                initialValue: selectedCatId,
                decoration: InputDecoration(
                  labelText: 'Filtrer par Catégorie',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes les catégories'),
                  ),
                  ...cats.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (val) {
                  ref.read(timetreePageCategoryFilterProvider.notifier).state = val;
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
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
          Text('Chargement des pages…'),
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
    final searchActive = ref.read(timetreePageSearchQueryProvider).isNotEmpty ||
        ref.read(timetreePageCategoryFilterProvider) != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive ? Icons.search_off_rounded : Icons.insert_drive_file_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              searchActive ? 'Aucune page correspondante' : 'Aucune page enregistrée',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchActive) ...[
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos filtres ou termes de recherche.',
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

class _PagesListView extends ConsumerWidget {
  const _PagesListView({required this.pages});

  final List<TimetreePage> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(timetreePagesProvider.notifier).loadPages();
        await ref.read(timetreeCategoriesProvider.notifier).loadCategories();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final p = pages[index];
          return _PageTile(page: p);
        },
      ),
    );
  }
}

class _PageTile extends ConsumerWidget {
  const _PageTile({required this.page});

  final TimetreePage page;

  void _handleEdit(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _PageFormDialog(page: page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(timetreeCategoriesProvider);

    // Resolve Category name for subtitle
    final String catName = categoriesAsync.maybeWhen(
      data: (cats) {
        try {
          return cats.firstWhere((c) => c.id == page.categoryId).name;
        } catch (_) {
          return 'Catégorie inconnue';
        }
      },
      orElse: () => 'Chargement…',
    );

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
          backgroundColor: page.active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.insert_drive_file_outlined,
            color: page.active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          page.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Catégorie : $catName • Ordre : ${page.displayOrder}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (page.allowedRoles != null && page.allowedRoles!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Rôles autorisés : ${page.allowedRoles}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (page.allowedUsers != null && page.allowedUsers!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Utilisateurs autorisés : ${page.allowedUsers}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: page.active,
              onChanged: (active) async {
                try {
                  await ref.read(timetreePagesProvider.notifier).togglePageActivation(page.id, active);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur de modification: $e')),
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Creation / Edition Form Modal
// ─────────────────────────────────────────────────────────────────────────────

class _PageFormDialog extends ConsumerStatefulWidget {
  const _PageFormDialog({this.page});

  final TimetreePage? page;

  @override
  ConsumerState<_PageFormDialog> createState() => _PageFormDialogState();
}

class _PageFormDialogState extends ConsumerState<_PageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _orderController;
  late TextEditingController _allowedRolesController;
  late TextEditingController _allowedUsersController;
  String? _selectedCategoryId;
  bool _active = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.page?.title ?? '');
    _orderController = TextEditingController(
      text: widget.page != null ? '${widget.page!.displayOrder}' : '1',
    );
    _allowedRolesController = TextEditingController(text: widget.page?.allowedRoles ?? '');
    _allowedUsersController = TextEditingController(text: widget.page?.allowedUsers ?? '');
    _selectedCategoryId = widget.page?.categoryId;
    _active = widget.page?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orderController.dispose();
    _allowedRolesController.dispose();
    _allowedUsersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    setState(() => _submitting = true);
    final title = _titleController.text.trim();
    final order = int.tryParse(_orderController.text) ?? 1;
    final allowedRoles = _allowedRolesController.text.trim();
    final allowedUsers = _allowedUsersController.text.trim();

    try {
      if (widget.page == null) {
        await ref.read(timetreePagesProvider.notifier).createPage(
              title: title,
              categoryId: _selectedCategoryId!,
              displayOrder: order,
              active: _active,
              allowedRoles: allowedRoles.isEmpty ? null : allowedRoles,
              allowedUsers: allowedUsers.isEmpty ? null : allowedUsers,
            );
      } else {
        await ref.read(timetreePagesProvider.notifier).updatePage(
              id: widget.page!.id,
              title: title,
              categoryId: _selectedCategoryId!,
              displayOrder: order,
              active: _active,
              allowedRoles: allowedRoles.isEmpty ? null : allowedRoles,
              allowedUsers: allowedUsers.isEmpty ? null : allowedUsers,
            );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.page == null ? 'Page créée avec succès' : 'Page modifiée avec succès',
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
    final categoriesAsync = ref.watch(timetreeCategoriesProvider);
    final dialogTitle = widget.page == null ? 'Ajouter une page' : 'Modifier la page';

    return AlertDialog(
      title: Text(dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la page',
                  hintText: 'ex. Conditions Générales, CGU',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown in form
              categoriesAsync.when(
                data: (cats) {
                  // If editing, verify selectedId exists in list (fall back to null if not found)
                  final exists = cats.any((c) => c.id == _selectedCategoryId);
                  final initialValue = exists ? _selectedCategoryId : null;

                  return DropdownButtonFormField<String>(
                    initialValue: initialValue,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                    ),
                    items: cats
                        .map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                    },
                    validator: (val) {
                      if (val == null) {
                        return 'Veuillez choisir une catégorie';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erreur de chargement des catégories: $e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => ref.read(timetreeCategoriesProvider.notifier).loadCategories(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _allowedRolesController,
                decoration: const InputDecoration(
                  labelText: 'Rôles autorisés',
                  hintText: 'Séparés par des virgules, ex. ADMIN, CHEF',
                  helperText: 'Laissez vide pour autoriser tous les rôles',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _allowedUsersController,
                decoration: const InputDecoration(
                  labelText: 'Utilisateurs autorisés',
                  hintText: 'Emails/Noms d\'utilisateurs séparés par des virgules',
                  helperText: 'Laissez vide pour autoriser tous les utilisateurs',
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Activer la page'),
                value: _active,
                onChanged: (val) => setState(() => _active = val),
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
