import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_members_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';

class TimetreeMembershipCalendarsScreen extends ConsumerStatefulWidget {
  const TimetreeMembershipCalendarsScreen({super.key});

  @override
  ConsumerState<TimetreeMembershipCalendarsScreen> createState() =>
      _TimetreeMembershipCalendarsScreenState();
}

class _TimetreeMembershipCalendarsScreenState
    extends ConsumerState<TimetreeMembershipCalendarsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimetreeCalendar? _selectedCalendar;

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
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role.toUpperCase() ?? 'MEMBER';
    final isAdmin = role == 'ADMIN' || role == 'ADMINISTRATEUR';

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Dux Calender – Membres & Agendas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline_rounded),
              text: 'Membres',
            ),
            Tab(
              icon: Icon(Icons.calendar_today_outlined),
              text: 'Agendas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Members
          isAdmin
              ? const _MembersTab()
              : const _RestrictedTabMessage(allowedRole: 'Admin'),

          // Tab 2: Calendars
          isAdmin
              ? const _CalendarsTab()
              : const _RestrictedTabMessage(allowedRole: 'Admin'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Restricted Tab View
// ─────────────────────────────────────────────────────────────────────────────
class _RestrictedTabMessage extends StatelessWidget {
  const _RestrictedTabMessage({required this.allowedRole});
  final String allowedRole;

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
              Icons.lock_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Accès Restreint',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seuls les utilisateurs avec le rôle "$allowedRole" peuvent accéder à cet onglet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Members Tab
// ─────────────────────────────────────────────────────────────────────────────
class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredTimetreeMembersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Search header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) =>
                  ref.read(timetreeMemberSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Rechercher un membre…',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Erreur: $err'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(timetreeMembersProvider.notifier).loadMembers(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Aucun membre trouvé.'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(timetreeMembersProvider.notifier).loadMembers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final m = list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(m.fullName),
                          subtitle: Text('${m.username} • ${m.email} • [${m.role}]'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showMemberDialog(context, ref, member: m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteMember(context, ref, m),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog(BuildContext context, WidgetRef ref, {TimetreeMember? member}) {
    showDialog<void>(
      context: context,
      builder: (context) => _MemberFormDialog(member: member),
    );
  }

  void _confirmDeleteMember(BuildContext context, WidgetRef ref, TimetreeMember member) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le membre ?'),
        content: Text('Voulez-vous vraiment supprimer ${member.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(timetreeMembersProvider.notifier).deleteMember(member.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membre supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _MemberFormDialog extends ConsumerStatefulWidget {
  const _MemberFormDialog({this.member});
  final TimetreeMember? member;

  @override
  ConsumerState<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late String _role;
  String? _selectedCalendarId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.member?.username ?? '');
    _fullNameCtrl = TextEditingController(text: widget.member?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.member?.email ?? '');
    _role = widget.member?.role ?? 'MEMBER';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.member != null && widget.member!.role == 'CHEF') {
        final calendars = ref.read(timetreeCalendarsProvider).value ?? [];
        try {
          final matchedCalendar = calendars.firstWhere(
            (c) => c.members.any((m) => m.id == widget.member!.id),
          );
          setState(() {
            _selectedCalendarId = matchedCalendar.id;
          });
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final calendars = calendarsAsync.value ?? [];

    return AlertDialog(
      title: Text(isEdit ? 'Modifier le membre' : 'Créer un membre'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(value: 'CHEF', child: Text('Chef')),
                  DropdownMenuItem(value: 'MEMBER', child: Text('Membres')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _role = val;
                      if (_role != 'CHEF') {
                        _selectedCalendarId = null;
                      } else if (_selectedCalendarId == null && calendars.isNotEmpty) {
                        _selectedCalendarId = calendars.first.id;
                      }
                    });
                  }
                },
              ),
              if (_role == 'CHEF' && calendars.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCalendarId ?? (calendars.isNotEmpty ? calendars.first.id : null),
                  decoration: const InputDecoration(labelText: 'Agenda associé'),
                  items: calendars.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCalendarId = val;
                    });
                  },
                  validator: (val) => val == null ? 'Veuillez sélectionner un agenda' : null,
                ),
              ],
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
          onPressed: _submitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() {
                    _submitting = true;
                  });
                  try {
                    final calendarIds = _role == 'CHEF' && _selectedCalendarId != null
                        ? [_selectedCalendarId!]
                        : null;
                    if (isEdit) {
                      await ref.read(timetreeMembersProvider.notifier).updateMember(
                            id: widget.member!.id,
                            username: _usernameCtrl.text,
                            fullName: _fullNameCtrl.text,
                            email: _emailCtrl.text,
                            role: _role,
                            calendarIds: calendarIds,
                          );
                    } else {
                      await ref.read(timetreeMembersProvider.notifier).createMember(
                            username: _usernameCtrl.text,
                            fullName: _fullNameCtrl.text,
                            email: _emailCtrl.text,
                            role: _role,
                            calendarIds: calendarIds,
                          );
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              isEdit ? 'Membre mis à jour' : 'Membre créé avec succès'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _submitting = false;
                      });
                    }
                  }
                },
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

// ─────────────────────────────────────────────────────────────────────────────
// Calendars Tab
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarsTab extends ConsumerWidget {
  const _CalendarsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.watch(filteredTimetreeCalendarsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCalendarDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Créer un agenda'),
      ),
      body: Column(
        children: [
          // Search header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) =>
                  ref.read(timetreeCalendarSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Rechercher un agenda…',
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
            child: calendarsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Erreur: $err'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(timetreeCalendarsProvider.notifier).loadCalendars(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Aucun agenda trouvé.'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(timetreeCalendarsProvider.notifier).loadCalendars(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final c = list[index];
                      // parse hex color
                      Color calendarColor = Colors.grey;
                      try {
                        final cleanHex = c.color.replaceAll('#', '');
                        calendarColor = Color(int.parse('FF$cleanHex', radix: 16));
                      } catch (_) {}

                      final chefs = c.members
                          .where((m) => m.role.toUpperCase() == 'CHEF')
                          .map((m) => m.fullName)
                          .toList();
                      final chefsText = chefs.isNotEmpty ? chefs.join(', ') : 'Aucun';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: calendarColor,
                            radius: 16,
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: calendarColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(c.description),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_pin_rounded,
                                    size: 14,
                                    color: chefs.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Chef : $chefsText',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: chefs.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                        color: chefs.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Badge(
                                label: Text('${c.members.length}'),
                                backgroundColor: theme.colorScheme.primary,
                                child: IconButton(
                                  icon: const Icon(Icons.people_outline_rounded),
                                  onPressed: () => _showManageCalendarMembersDialog(context, ref, c),
                                  tooltip: 'Gérer les membres',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showCalendarDialog(context, ref, calendar: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteCalendar(context, ref, c),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showManageCalendarMembersDialog(BuildContext context, WidgetRef ref, TimetreeCalendar calendar) {
    showDialog<void>(
      context: context,
      builder: (context) => _ManageCalendarMembersDialog(calendar: calendar),
    );
  }

  void _showCalendarDialog(BuildContext context, WidgetRef ref, {TimetreeCalendar? calendar}) {
    showDialog<void>(
      context: context,
      builder: (context) => _CalendarFormDialog(calendar: calendar),
    );
  }

  void _confirmDeleteCalendar(BuildContext context, WidgetRef ref, TimetreeCalendar calendar) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agenda ?'),
        content: Text('Voulez-vous vraiment supprimer ${calendar.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(timetreeCalendarsProvider.notifier).deleteCalendar(calendar.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agenda supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _CalendarFormDialog extends ConsumerStatefulWidget {
  const _CalendarFormDialog({this.calendar});
  final TimetreeCalendar? calendar;

  @override
  ConsumerState<_CalendarFormDialog> createState() => _CalendarFormDialogState();
}

class _CalendarFormDialogState extends ConsumerState<_CalendarFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late String _colorHex;
  bool _submitting = false;
  List<String> _selectedDocs = [];
  List<String> _selectedTiers = [];
  Set<String> _tierCodes = {};

  final List<String> _colorPalette = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#F44336', // Red
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#009688', // Teal
    '#E91E63', // Pink
    '#3F51B5', // Indigo
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.calendar?.name ?? '');
    _descCtrl = TextEditingController(text: widget.calendar?.description ?? '');
    _colorHex = widget.calendar?.color ?? '#2196F3';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarAttachedEntities();
    });
  }

  Future<void> _loadCalendarAttachedEntities() async {
    try {
      final tierTypes = await ref.read(screenConfigControllerProvider.notifier).fetchAllTierTypes();
      _tierCodes = tierTypes
          .map((t) => (t['typeCode'] ?? t['code'])?.toString().trim().toUpperCase())
          .where((c) => c != null)
          .cast<String>()
          .toSet();

      final attached = widget.calendar?.attachedDocuments?.split(',') ?? [];
      final docs = <String>[];
      final tiers = <String>[];
      for (final code in attached) {
        final trimmed = code.trim();
        if (trimmed.isEmpty) continue;
        if (_tierCodes.contains(trimmed.toUpperCase())) {
          tiers.add(trimmed);
        } else {
          docs.add(trimmed);
        }
      }
      if (mounted) {
        setState(() {
          _selectedDocs = docs;
          _selectedTiers = tiers;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showDocumentSelectorDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    List<Map<String, dynamic>> allClasses = [];
    try {
      allClasses = await ref.read(screenConfigControllerProvider.notifier).fetchAllDocumentClasses();
    } catch (e) {
      debugPrint('Error fetching all document classes: $e');
    }

    if (context.mounted) {
      Navigator.pop(context); // close loading
    }

    if (allClasses.isEmpty) {
      allClasses = [
        {'code': 'BC', 'libelle': 'Bon de Commande (BC)'},
        {'code': 'BP', 'libelle': 'Bon de Préparation (BP)'},
        {'code': 'BS', 'libelle': 'Bon de Sortie (BS)'},
      ];
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DocumentSelectorSearchDialog(
          allClasses: allClasses,
          initialSelected: List<String>.from(_selectedDocs),
          onChanged: (selected) {
            setState(() {
              _selectedDocs = selected;
            });
          },
        );
      },
    );
  }

  void _showTierSelectorDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    List<Map<String, dynamic>> allClasses = [];
    try {
      allClasses = await ref.read(screenConfigControllerProvider.notifier).fetchAllTierTypes();
    } catch (e) {
      debugPrint('Error fetching all tier types: $e');
    }

    if (context.mounted) {
      Navigator.pop(context); // close loading
    }

    if (allClasses.isEmpty) {
      allClasses = [
        {'code': '1', 'libelle': 'Client'},
      ];
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DocumentSelectorSearchDialog(
          allClasses: allClasses,
          initialSelected: List<String>.from(_selectedTiers),
          onChanged: (selected) {
            setState(() {
              _selectedTiers = selected;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.calendar != null;
    final theme = Theme.of(context);
    Color parsedColor = Colors.blue;
    try {
      final cleanHex = _colorHex.replaceAll('#', '');
      parsedColor = Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {}

    return Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: parsedColor,
          brightness: theme.brightness,
          primary: parsedColor,
        ),
      ),
      child: AlertDialog(
        title: Text(isEdit ? 'Modifier l\'agenda' : 'Créer un agenda'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l\'agenda'),
                  validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Couleur de l\'agenda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPalette.map((colorStr) {
                    final cleanHex = colorStr.replaceAll('#', '');
                    final col = Color(int.parse('FF$cleanHex', radix: 16));
                    final isSelected = _colorHex.toUpperCase() == colorStr.toUpperCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _colorHex = colorStr;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Documents associés', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showDocumentSelectorDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Sélectionner des documents',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: _selectedDocs.isEmpty
                        ? const Text('Aucun document associé')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedDocs.map((docType) {
                              return Chip(
                                label: Text(docType),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedDocs.remove(docType);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tiers associés', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showTierSelectorDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Sélectionner des tiers',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: _selectedTiers.isEmpty
                        ? const Text('Aucun tiers associé')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedTiers.map((tierType) {
                              return Chip(
                                label: Text(tierType),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedTiers.remove(tierType);
                                  });
                                },
                              );
                            }).toList(),
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
            onPressed: _submitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() {
                      _submitting = true;
                    });
                    try {
                      final joinedAttached = [..._selectedDocs, ..._selectedTiers].join(',');
                      if (isEdit) {
                        await ref.read(timetreeCalendarsProvider.notifier).updateCalendar(
                              id: widget.calendar!.id,
                              name: _nameCtrl.text,
                              description: _descCtrl.text,
                              color: _colorHex,
                              attachedDocuments: joinedAttached,
                            );
                      } else {
                        await ref.read(timetreeCalendarsProvider.notifier).createCalendar(
                              name: _nameCtrl.text,
                              description: _descCtrl.text,
                              color: _colorHex,
                              attachedDocuments: joinedAttached,
                            );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                isEdit ? 'Agenda mis à jour' : 'Agenda créé avec succès'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _submitting = false;
                        });
                      }
                    }
                  },
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _ManageCalendarMembersDialog extends ConsumerStatefulWidget {
  final TimetreeCalendar calendar;
  const _ManageCalendarMembersDialog({required this.calendar});

  @override
  ConsumerState<_ManageCalendarMembersDialog> createState() => _ManageCalendarMembersDialogState();
}

class _ManageCalendarMembersDialogState extends ConsumerState<_ManageCalendarMembersDialog> {
  bool _loading = false;
  late List<TimetreeMember> _currentMembers;

  @override
  void initState() {
    super.initState();
    _currentMembers = List.from(widget.calendar.members);
  }

  Future<void> _removeMember(TimetreeMember member) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(timetreeCalendarsRepositoryProvider);
      await repo.removeMemberFromCalendar(widget.calendar.id, member.id);
      setState(() {
        _currentMembers.removeWhere((m) => m.id == member.id);
      });
      ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.fullName} retiré de l\'agenda')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addMember(TimetreeMember member) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(timetreeCalendarsRepositoryProvider);
      await repo.addMemberToCalendar(widget.calendar.id, member.id);
      setState(() {
        _currentMembers.add(member);
      });
      ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.fullName} ajouté à l\'agenda')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddMemberSelection() async {
    final membersRepo = ref.read(timetreeMembersRepositoryProvider);
    try {
      final allMembers = await membersRepo.getMembers();
      final available = allMembers
          .where((m) => !_currentMembers.any((existing) => existing.id == m.id))
          .toList();

      if (!mounted) return;

      if (available.isEmpty) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ajouter des membres'),
            content: const Text('Tous les membres du système font déjà partie de cet agenda.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          ),
        );
        return;
      }

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sélectionner un membre'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, index) {
                final m = available[index];
                return ListTile(
                  title: Text(m.fullName),
                  subtitle: Text('${m.username} • ${m.role}'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () async {
                    Navigator.pop(context);
                    await _addMember(m);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Membres – ${widget.calendar.name} (${_currentMembers.length})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _loading ? null : _showAddMemberSelection,
            tooltip: 'Ajouter un membre',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _currentMembers.isEmpty
                ? Center(
                    child: Text(
                      'Aucun membre dans cet agenda.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _currentMembers.length,
                    itemBuilder: (context, index) {
                      final m = _currentMembers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(m.fullName, overflow: TextOverflow.ellipsis, maxLines: 1),
                        subtitle: Text(m.role, overflow: TextOverflow.ellipsis, maxLines: 1),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeMember(m),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _DocumentSelectorSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allClasses;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;

  const _DocumentSelectorSearchDialog({
    required this.allClasses,
    required this.initialSelected,
    required this.onChanged,
  });

  @override
  State<_DocumentSelectorSearchDialog> createState() => _DocumentSelectorSearchDialogState();
}

class _DocumentSelectorSearchDialogState extends State<_DocumentSelectorSearchDialog> {
  late List<String> _tempSelected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.allClasses.where((doc) {
      final code = (doc['code'] ?? '').toString().toLowerCase();
      final libelle = (doc['libelle'] ?? '').toString().toLowerCase();
      return code.contains(_searchQuery.toLowerCase()) || libelle.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Documents associés',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un document...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun document trouvé',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final code = (item['code'] ?? '').toString();
                        final libelle = (item['libelle'] ?? '').toString();
                        final isChecked = _tempSelected.contains(code);

                        return CheckboxListTile(
                          title: Text(
                            libelle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            code,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          value: isChecked,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                if (!_tempSelected.contains(code)) {
                                  _tempSelected.add(code);
                                }
                              } else {
                                _tempSelected.remove(code);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

