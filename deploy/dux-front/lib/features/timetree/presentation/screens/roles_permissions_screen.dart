import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_role.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_permission.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_roles_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';

/// Screen for managing TimeTree Roles & Permissions.
///
/// Organized into two tabs:
///   1. Rôles: Listing group role assignments, adding and removing roles.
///   2. Permissions: Permissions Matrix mapping categories and pages to groups.
class TimetreeRolesPermissionsScreen extends ConsumerStatefulWidget {
  const TimetreeRolesPermissionsScreen({super.key});

  @override
  ConsumerState<TimetreeRolesPermissionsScreen> createState() => _TimetreeRolesPermissionsScreenState();
}

class _TimetreeRolesPermissionsScreenState extends ConsumerState<TimetreeRolesPermissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const DuxDrawer(),
        appBar: AppBar(
          title: const Text('TimeTree – Rôles & Permissions'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.group_outlined), text: 'Assignation des Rôles'),
              Tab(icon: Icon(Icons.grid_on_outlined), text: 'Matrice des Permissions'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _RolesTab(),
            _PermissionsTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _RolesTab extends ConsumerStatefulWidget {
  const _RolesTab();

  @override
  ConsumerState<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends ConsumerState<_RolesTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(timetreeRolesProvider);
    final groupsAsync = ref.watch(timetreeGroupsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Rechercher un groupe par nom…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        Expanded(
          child: rolesAsync.when(
            loading: () => const _LoadingState(message: 'Chargement des rôles…'),
            error: (err, _) => _ErrorState(
              message: err.toString(),
              onRetry: () => ref.read(timetreeRolesProvider.notifier).loadRoles(),
            ),
            data: (roles) {
              if (roles.isEmpty) {
                return const _EmptyState(
                  message: 'Aucun rôle disponible sur le serveur',
                  icon: Icons.security_outlined,
                );
              }

              return groupsAsync.when(
                loading: () => const _LoadingState(message: 'Chargement des groupes…'),
                error: (err, _) => _ErrorState(
                  message: err.toString(),
                  onRetry: () => ref.read(timetreeGroupsProvider.notifier).loadGroups(),
                ),
                data: (groups) {
                  final filteredGroups = groups
                      .where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

                  if (filteredGroups.isEmpty) {
                    return const _EmptyState(
                      message: 'Aucun groupe correspondant à la recherche',
                      icon: Icons.group_off_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, idx) {
                      final group = filteredGroups[idx];
                      return _GroupRoleCard(group: group, availableRoles: roles);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupRoleCard extends ConsumerWidget {
  const _GroupRoleCard({required this.group, required this.availableRoles});

  final TimetreeGroup group;
  final List<TimetreeRole> availableRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.description,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _showAssignRoleDialog(context, ref),
                  icon: const Icon(Icons.add_moderator_rounded),
                  tooltip: 'Assigner un rôle',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rôles assignés :',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (group.roles.isEmpty)
              Text(
                'Aucun rôle assigné à ce groupe.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.roles.map((roleCode) {
                  final roleName = availableRoles.firstWhere(
                    (r) => r.code == roleCode,
                    orElse: () => TimetreeRole(code: roleCode, name: roleCode),
                  ).name;

                  return Chip(
                    label: Text(roleName),
                    backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () => _removeRole(context, ref, roleCode),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showAssignRoleDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assigner un rôle à "${group.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableRoles.map((role) {
            final isAlreadyAssigned = group.roles.contains(role.code);

            return ListTile(
              title: Text(role.name),
              subtitle: Text(role.code),
              trailing: isAlreadyAssigned
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              enabled: !isAlreadyAssigned,
              onTap: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await ref.read(timetreeRolesProvider.notifier).assignRoleToGroup(group.id, role.code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rôle "${role.name}" assigné avec succès.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Échec de l\'assignation : ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            );
          }).toList(),
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

  Future<void> _removeRole(BuildContext context, WidgetRef ref, String roleCode) async {
    try {
      await ref.read(timetreeRolesProvider.notifier).removeRoleFromGroup(group.id, roleCode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôle retiré avec succès.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec du retrait du rôle : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSIONS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsTab extends ConsumerStatefulWidget {
  const _PermissionsTab();

  @override
  ConsumerState<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends ConsumerState<_PermissionsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(timetreePermissionsProvider);
    final groupsAsync = ref.watch(timetreeGroupsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Rechercher une catégorie ou page…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        Expanded(
          child: permissionsAsync.when(
            loading: () => const _LoadingState(message: 'Chargement de la matrice des permissions…'),
            error: (err, _) => _ErrorState(
              message: err.toString(),
              onRetry: () => ref.read(timetreePermissionsProvider.notifier).loadPermissions(),
            ),
            data: (matrix) {
              return groupsAsync.when(
                loading: () => const _LoadingState(message: 'Chargement des groupes…'),
                error: (err, _) => _ErrorState(
                  message: err.toString(),
                  onRetry: () => ref.read(timetreeGroupsProvider.notifier).loadGroups(),
                ),
                data: (groups) {
                  final filteredCategories = matrix.categories
                      .where((cat) => cat.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

                  final filteredPages = matrix.pages
                      .where((p) => p.pageName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

                  if (filteredCategories.isEmpty && filteredPages.isEmpty) {
                    return const _EmptyState(
                      message: 'Aucun élément correspondant à la recherche',
                      icon: Icons.grid_off_outlined,
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (filteredCategories.isNotEmpty) ...[
                        Text(
                          'Permissions de Catégories',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...filteredCategories.map((cat) => _CategoryPermissionCard(
                              permission: cat,
                              allGroups: groups,
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (filteredPages.isNotEmpty) ...[
                        Text(
                          'Permissions de Pages',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...filteredPages.map((page) => _PagePermissionCard(
                              permission: page,
                              allGroups: groups,
                            )),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPermissionCard extends ConsumerWidget {
  const _CategoryPermissionCard({required this.permission, required this.allGroups});

  final TimetreeCategoryPermission permission;
  final List<TimetreeGroup> allGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          permission.categoryName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groupes autorisés :',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              if (permission.groupIds.isEmpty)
                Text(
                  'Aucun groupe (accessible uniquement aux admins)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: permission.groupIds.map<Widget>((gid) {
                    final groupName = allGroups.firstWhere(
                      (g) => g.id == gid,
                      orElse: () => TimetreeGroup(id: gid, name: 'ID: $gid', description: '', active: false, roles: []),
                    ).name;

                    return Chip(
                      label: Text(groupName),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.security_rounded),
          onPressed: () => _showEditPermissionsDialog(context, ref),
          tooltip: 'Gérer les groupes autorisés',
        ),
      ),
    );
  }

  void _showEditPermissionsDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditPermissionsDialog(
        title: 'Permissions pour ${permission.categoryName}',
        allGroups: allGroups,
        selectedGroupIds: permission.groupIds,
        onSave: (groupIds) async {
          await ref.read(timetreePermissionsProvider.notifier).updateCategoryPermissions(permission.categoryId, groupIds);
        },
      ),
    );
  }
}

class _PagePermissionCard extends ConsumerWidget {
  const _PagePermissionCard({required this.permission, required this.allGroups});

  final TimetreePagePermission permission;
  final List<TimetreeGroup> allGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          permission.pageName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groupes autorisés :',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              if (permission.groupIds.isEmpty)
                Text(
                  'Aucun groupe (accessible uniquement aux admins)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: permission.groupIds.map<Widget>((gid) {
                    final groupName = allGroups.firstWhere(
                      (g) => g.id == gid,
                      orElse: () => TimetreeGroup(id: gid, name: 'ID: $gid', description: '', active: false, roles: []),
                    ).name;

                    return Chip(
                      label: Text(groupName),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.security_rounded),
          onPressed: () => _showEditPermissionsDialog(context, ref),
          tooltip: 'Gérer les groupes autorisés',
        ),
      ),
    );
  }

  void _showEditPermissionsDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditPermissionsDialog(
        title: 'Permissions pour ${permission.pageName}',
        allGroups: allGroups,
        selectedGroupIds: permission.groupIds,
        onSave: (groupIds) async {
          await ref.read(timetreePermissionsProvider.notifier).updatePagePermissions(permission.pageId, groupIds);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG & COMMON STATES
// ─────────────────────────────────────────────────────────────────────────────

class _EditPermissionsDialog extends StatefulWidget {
  const _EditPermissionsDialog({
    required this.title,
    required this.allGroups,
    required this.selectedGroupIds,
    required this.onSave,
  });

  final String title;
  final List<TimetreeGroup> allGroups;
  final List<String> selectedGroupIds;
  final Future<void> Function(List<String> groupIds) onSave;

  @override
  State<_EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<_EditPermissionsDialog> {
  late List<String> _localSelected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _localSelected = List.from(widget.selectedGroupIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: widget.allGroups.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucun groupe de sécurité disponible. Veuillez créer un groupe d\'abord.',
                textAlign: TextAlign.center,
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allGroups.length,
                itemBuilder: (context, idx) {
                  final group = widget.allGroups[idx];
                  final isChecked = _localSelected.contains(group.id);

                  return CheckboxListTile(
                    title: Text(group.name),
                    subtitle: group.description.isNotEmpty ? Text(group.description) : null,
                    value: isChecked,
                    onChanged: _saving
                        ? null
                        : (val) {
                            setState(() {
                              if (val == true) {
                                _localSelected.add(group.id);
                              } else {
                                _localSelected.remove(group.id);
                              }
                            });
                          },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (widget.allGroups.isNotEmpty)
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      // Call onSave function
                      await widget.onSave(_localSelected);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        // Show "Permission update confirmation" dialog or snackbar
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Succès'),
                              ],
                            ),
                            content: const Text('Les permissions ont été mises à jour avec succès.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => _saving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de l\'enregistrement : ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
