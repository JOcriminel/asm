import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

class TimetreeEventTraceabilityScreen extends ConsumerStatefulWidget {
  const TimetreeEventTraceabilityScreen({super.key});

  @override
  ConsumerState<TimetreeEventTraceabilityScreen> createState() => _TimetreeEventTraceabilityScreenState();
}

class _TimetreeEventTraceabilityScreenState extends ConsumerState<TimetreeEventTraceabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedCalendarId;
  String? _selectedEventId;
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  List<TimetreeEvent> _events = [];
  bool _loadingEvents = false;

  List<TimetreeAuditLog> _allLogs = [];
  List<TimetreeAuditLog> _filteredLogs = [];
  bool _loadingLogs = false;
  bool _isExporting = false;

  final List<String> _actions = ['CREATE', 'UPDATE', 'DELETE', 'UPDATE_VALUES'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents(String calendarId) async {
    setState(() {
      _loadingEvents = true;
      _events = [];
      _selectedEventId = null;
      _allLogs = [];
      _filteredLogs = [];
    });

    try {
      final repo = ref.read(timetreeEventsProviderProvider);
      final list = await repo.getEvents(
        calendarIds: [calendarId],
        start: DateTime.now().subtract(const Duration(days: 365)),
        end: DateTime.now().add(const Duration(days: 365)),
      );

      // Sort events by date descending
      list.sort((a, b) => b.startDate.compareTo(a.startDate));

      if (mounted) {
        setState(() {
          _events = list;
          _loadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEvents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des événements: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadEventHistory(String eventId) async {
    setState(() {
      _loadingLogs = true;
      _allLogs = [];
      _filteredLogs = [];
    });

    try {
      final repo = ref.read(timetreeEventsProviderProvider);
      final logs = await repo.getEventHistory(eventId);

      if (mounted) {
        setState(() {
          _allLogs = logs;
          _loadingLogs = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLogs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement de l\'historique: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        // Filter by action
        if (_selectedAction != null && log.action.toUpperCase() != _selectedAction!.toUpperCase()) {
          return false;
        }

        // Filter by date range
        if (_startDate != null && log.actionDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null) {
          final endOfDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (log.actionDate.isAfter(endOfDate)) {
            return false;
          }
        }

        // Filter by text search
        if (search.isNotEmpty) {
          final user = (log.username ?? '').toLowerCase();
          final details = (log.details ?? '').toLowerCase();
          if (!user.contains(search) && !details.contains(search)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedAction = null;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _applyFilters();
    }
  }

  Future<void> _exportCsv() async {
    if (_filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun log à exporter'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/event_traceability_${_selectedEventId}_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      final sink = file.openWrite();
      sink.write('ID,ActionDate,Username,Action,Result,IPAddress,Details\n');
      for (final log in _filteredLogs) {
        sink.write('${log.id},${log.actionDate.toIso8601String()},"${log.username ?? ''}","${log.action}","${log.result ?? ''}","${log.ipAddress ?? ''}","${(log.details ?? '').replaceAll('"', '""')}"\n');
      }
      await sink.close();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Historique exporté avec succès !\nSauvegardé dans: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'exportation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Security guard check
    if (user == null || 
        (user.role.toUpperCase() != 'ADMIN' && 
         user.role.toUpperCase() != 'ADMINISTRATEUR' && 
         user.role.toUpperCase() != 'CHEF')) {
      return Scaffold(
        drawer: const DuxDrawer(),
        appBar: AppBar(title: const Text('Accès Refusé')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 80, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Accès réservé aux administrateurs et chefs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Vous n\'avez pas les droits requis pour afficher cette traçabilité.'),
            ],
          ),
        ),
      );
    }

    final calendarsState = ref.watch(timetreeCalendarsProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Traçabilité des Événements'),
        elevation: 0,
        actions: [
          if (_selectedEventId != null) ...[
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: const Icon(Icons.file_download_rounded),
                tooltip: 'Exporter en CSV',
                onPressed: _exportCsv,
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _loadEventHistory(_selectedEventId!),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Selector Card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez un agenda et un événement',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  
                  // Calendar Dropdown Selection
                  calendarsState.when(
                    data: (calendars) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCalendarId,
                        decoration: const InputDecoration(
                          labelText: 'Agenda / Calendrier',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        items: calendars.map((cal) {
                          return DropdownMenuItem(
                            value: cal.id,
                            child: Text(cal.name),
                          );
                        }).toList(),
                        onChanged: (calId) {
                          if (calId != null) {
                            setState(() => _selectedCalendarId = calId);
                            _loadEvents(calId);
                          }
                        },
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (err, _) => Text('Erreur agenda: $err', style: const TextStyle(color: Colors.red)),
                  ),
                  
                  if (_selectedCalendarId != null) ...[
                    const SizedBox(height: 12),
                    // Event Dropdown Selection
                    _loadingEvents
                        ? const Center(child: LinearProgressIndicator())
                        : _events.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Aucun événement trouvé pour cet agenda au cours de l\'année.'),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedEventId,
                                decoration: const InputDecoration(
                                  labelText: 'Événement',
                                  prefixIcon: Icon(Icons.event_note_rounded),
                                ),
                                isExpanded: true,
                                items: _events.map((ev) {
                                  final dateStr = DateFormat('dd/MM/yyyy').format(ev.startDate);
                                  return DropdownMenuItem(
                                    value: ev.id,
                                    child: Text(
                                      '${ev.title} ($dateStr)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (evId) {
                                  if (evId != null) {
                                    setState(() => _selectedEventId = evId);
                                    _loadEventHistory(evId);
                                  }
                                },
                              ),
                  ],
                ],
              ),
            ),
          ),

          // Filters Card (Only visible when event history is loaded)
          if (_selectedEventId != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ExpansionTile(
                leading: Icon(Icons.filter_alt_outlined, color: theme.colorScheme.primary),
                title: const Text('Filtres de recherche', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                childrenPadding: const EdgeInsets.all(12),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Filtrer par texte',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onChanged: (_) => _applyFilters(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAction,
                          decoration: const InputDecoration(labelText: 'Action'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Toutes')),
                            ..._actions.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedAction = val);
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(_startDate == null ? 'Date début' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                          onPressed: () => _selectStartDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(_endDate == null ? 'Date fin' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                          onPressed: () => _selectEndDate(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Réinitialiser'),
                        onPressed: _clearFilters,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Audit History List View
          Expanded(
            child: _selectedEventId == null
                ? const Center(
                    child: Text('Veuillez sélectionner un agenda et un événement pour afficher l\'historique.')
                  )
                : _loadingLogs
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLogs.isEmpty
                        ? const Center(child: Text('Aucune trace d\'activité trouvée.'))
                        : ListView.builder(
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final logItem = _filteredLogs[index];
                              return _TraceabilityTile(logItem: logItem, isDark: isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _TraceabilityTile extends StatelessWidget {
  const _TraceabilityTile({required this.logItem, required this.isDark});

  final TimetreeAuditLog logItem;
  final bool isDark;

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'UPDATE_VALUES':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(logItem.actionDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _actionColor(logItem.action).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            logItem.action,
            style: TextStyle(
              color: _actionColor(logItem.action),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        title: Text(
          logItem.details ?? '${logItem.action} ${logItem.entityType}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(logItem.username ?? 'Système', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(fmtDate, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.computer_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(logItem.ipAddress ?? '0.0.0.0', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
