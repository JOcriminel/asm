import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_permission.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_roles_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';

/// Screen for managing TimeTree Roles & Permissions.
///
/// Organized into two tabs:
///   1. Matrice des Permissions: Permissions Matrix mapping categories and pages.
///   2. Accès Utilisateurs: Member role management.
class TimetreeRolesPermissionsScreen extends ConsumerWidget {
  const TimetreeRolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Dux Calender – Rôles & Permissions'),
        elevation: 0,
      ),
      body: const _UserAccessTab(),
    );
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
                    ...filteredCategories.map((cat) => _CategoryPermissionCard(permission: cat)),
                    const SizedBox(height: 24),
                  ],
                  if (filteredPages.isNotEmpty) ...[
                    Text(
                      'Permissions de Pages',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...filteredPages.map((page) => _PagePermissionCard(permission: page)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPermissionCard extends ConsumerWidget {
  const _CategoryPermissionCard({required this.permission});

  final TimetreeCategoryPermission permission;

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
      ),
    );
  }
}

class _PagePermissionCard extends ConsumerWidget {
  const _PagePermissionCard({required this.permission});

  final TimetreePagePermission permission;

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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMON STATES
// ─────────────────────────────────────────────────────────────────────────────

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

class _UserAccessTab extends ConsumerStatefulWidget {
  const _UserAccessTab();

  @override
  ConsumerState<_UserAccessTab> createState() => _UserAccessTabState();
}

class _UserAccessTabState extends ConsumerState<_UserAccessTab> {
  String _searchQuery = '';

  Future<String?> _showChefAgendaDialog(BuildContext context, List<TimetreeCalendar> calendars) {
    TimetreeCalendar? selected = calendars.isNotEmpty ? calendars.first : null;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sélectionner l\'agenda'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Veuillez sélectionner l\'agenda dont cet utilisateur sera le chef :'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TimetreeCalendar>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Agenda',
                      border: OutlineInputBorder(),
                    ),
                    items: calendars.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selected = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: selected == null ? null : () => Navigator.pop(context, selected!.id),
                  child: const Text('Valider'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(timetreeMembersProvider);
    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur par nom…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        Expanded(
          child: membersAsync.when(
            loading: () => const _LoadingState(message: 'Chargement des utilisateurs…'),
            error: (err, _) => _ErrorState(
              message: err.toString(),
              onRetry: () => ref.read(timetreeMembersProvider.notifier).loadMembers(),
            ),
            data: (members) {
              final filteredMembers = members.where((m) {
                final query = _searchQuery.toLowerCase();
                return m.fullName.toLowerCase().contains(query) ||
                    m.username.toLowerCase().contains(query);
              }).toList();

              if (filteredMembers.isEmpty) {
                return const _EmptyState(
                  message: 'Aucun utilisateur trouvé',
                  icon: Icons.person_off_rounded,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredMembers.length,
                itemBuilder: (context, idx) {
                  final member = filteredMembers[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: member.profilePicture != null && member.profilePicture!.isNotEmpty
                                  ? MemoryImage(base64Decode(member.profilePicture!))
                                  : null,
                              child: member.profilePicture != null && member.profilePicture!.isNotEmpty
                                  ? null
                                  : Text(member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?'),
                            ),
                            title: Text(
                              member.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${member.username} • ${member.role}'),
                                if (member.role.toUpperCase() == 'CHEF') ...[
                                  (() {
                                    final calendars = calendarsAsync.value ?? [];
                                    final chefCalNames = calendars
                                        .where((c) => c.members.any((m) => m.id == member.id))
                                        .map((c) => c.name)
                                        .join(', ');
                                    if (chefCalNames.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Chef de : $chefCalNames',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  })(),
                                ],
                              ],
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                const Text('Rôle d\'accès: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: ['ADMIN', 'CHEF', 'MEMBER', 'ADMINISTRATEUR'].contains(member.role.toUpperCase())
                                        ? (member.role.toUpperCase() == 'ADMINISTRATEUR' ? 'ADMIN' : member.role.toUpperCase())
                                        : 'MEMBER',
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'ADMIN',
                                        child: Text('Administrateur (ADMIN)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CHEF',
                                        child: Text('Chef de Calendrier (CHEF)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'MEMBER',
                                        child: Text('Membre (MEMBER)'),
                                      ),
                                    ],
                                    onChanged: (newRole) async {
                                      if (newRole != null && newRole != member.role.toUpperCase()) {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        List<String>? calendarIds;
                                        if (newRole == 'CHEF') {
                                          final calendars = calendarsAsync.value ?? [];
                                          if (calendars.isEmpty) {
                                            scaffoldMessenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Aucun agenda disponible pour affectation.'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }
                                          final selectedId = await _showChefAgendaDialog(context, calendars);
                                          if (selectedId == null) return;
                                          calendarIds = [selectedId];
                                        }
                                        try {
                                          await ref.read(timetreeMembersProvider.notifier).updateMember(
                                            id: member.id,
                                            username: member.username,
                                            fullName: member.fullName,
                                            email: member.email,
                                            role: newRole,
                                            canCreateAgendas: newRole != 'MEMBER',
                                            canAddMembers: newRole != 'MEMBER',
                                            calendarIds: calendarIds,
                                          );
                                          scaffoldMessenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('Rôle mis à jour avec succès.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

