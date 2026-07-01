import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_categories_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ordre d\'affichage : ${category.displayOrder}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (category.allowedRoles != null && category.allowedRoles!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Rôles autorisés : ${category.allowedRoles}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (category.allowedUsers != null && category.allowedUsers!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Utilisateurs autorisés : ${category.allowedUsers}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
  List<String> _selectedRoles = [];
  List<String> _selectedUsers = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _orderController = TextEditingController(
      text: widget.category != null ? '${widget.category!.displayOrder}' : '1',
    );
    _selectedRoles = widget.category?.allowedRoles?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
    _selectedUsers = widget.category?.allowedUsers?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];

    Future.microtask(() {
      if (ref.read(timetreeMembersProvider).value == null) {
        ref.read(timetreeMembersProvider.notifier).loadMembers();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _showRolesSelectorDialog() {
    List<String> tempRoles = List.from(_selectedRoles);
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rôles autorisés'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['ADMIN', 'CHEF', 'MEMBER'].map((role) {
                  final checked = tempRoles.contains(role);
                  return CheckboxListTile(
                    title: Text(role),
                    value: checked,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          tempRoles.add(role);
                        } else {
                          tempRoles.remove(role);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _selectedRoles = tempRoles;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUsersSelectorDialog() {
    List<String> tempUsers = List.from(_selectedUsers);
    String searchQuery = '';
    int currentPage = 0;
    const int pageSize = 5;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allMembers = ref.watch(timetreeMembersProvider).value ?? [];
            final filteredMembers = allMembers.where((m) {
              final term = searchQuery.toLowerCase();
              return m.fullName.toLowerCase().contains(term) ||
                     m.username.toLowerCase().contains(term) ||
                     m.email.toLowerCase().contains(term);
            }).toList();

            final totalItems = filteredMembers.length;
            final totalPages = (totalItems / pageSize).ceil();
            final startIdx = currentPage * pageSize;
            final endIdx = (startIdx + pageSize) > totalItems ? totalItems : (startIdx + pageSize);
            final currentPageItems = totalItems > 0 ? filteredMembers.sublist(startIdx, endIdx) : <TimetreeMember>[];

            return AlertDialog(
              title: const Text('Utilisateurs autorisés'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un utilisateur...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                          currentPage = 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (currentPageItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Aucun utilisateur trouvé'),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: currentPageItems.map((m) {
                            final isChecked = tempUsers.contains(m.username);
                            return CheckboxListTile(
                              title: Text(m.fullName),
                              subtitle: Text('@${m.username}'),
                              value: isChecked,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    if (!tempUsers.contains(m.username)) {
                                      tempUsers.add(m.username);
                                    }
                                  } else {
                                    tempUsers.remove(m.username);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    if (totalPages > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: currentPage > 0
                                ? () {
                                    setDialogState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text('Page ${currentPage + 1} sur $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: currentPage < totalPages - 1
                                ? () {
                                    setDialogState(() {
                                      currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _selectedUsers = tempUsers;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final name = _nameController.text.trim();
    final order = int.tryParse(_orderController.text) ?? 1;
    final allowedRoles = _selectedRoles.join(', ');
    final allowedUsers = _selectedUsers.join(', ');

    try {
      if (widget.category == null) {
        // Create mode
        await ref.read(timetreeCategoriesProvider.notifier).createCategory(
              name: name,
              displayOrder: order,
              allowedRoles: allowedRoles.isEmpty ? null : allowedRoles,
              allowedUsers: allowedUsers.isEmpty ? null : allowedUsers,
            );
      } else {
        // Edit mode
        await ref.read(timetreeCategoriesProvider.notifier).updateCategory(
              id: widget.category!.id,
              name: name,
              displayOrder: order,
              allowedRoles: allowedRoles.isEmpty ? null : allowedRoles,
              allowedUsers: allowedUsers.isEmpty ? null : allowedUsers,
            );
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
      content: SingleChildScrollView(
        child: Form(
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
              const SizedBox(height: 16),

              InkWell(
                onTap: _showRolesSelectorDialog,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Rôles autorisés',
                    helperText: 'Laissez vide pour autoriser tous les rôles',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedRoles.isEmpty
                        ? 'Tous les rôles'
                        : _selectedRoles.join(', '),
                    style: TextStyle(
                      color: _selectedRoles.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showUsersSelectorDialog,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Utilisateurs autorisés',
                    helperText: 'Laissez vide pour autoriser tous les utilisateurs',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedUsers.isEmpty
                        ? 'Tous les utilisateurs'
                        : _selectedUsers.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedUsers.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ),
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
