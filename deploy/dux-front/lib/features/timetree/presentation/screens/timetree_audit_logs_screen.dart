import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_audit_logs_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

class TimetreeAuditLogsScreen extends ConsumerStatefulWidget {
  const TimetreeAuditLogsScreen({super.key});

  @override
  ConsumerState<TimetreeAuditLogsScreen> createState() => _TimetreeAuditLogsScreenState();
}

class _TimetreeAuditLogsScreenState extends ConsumerState<TimetreeAuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _entityIdController = TextEditingController();
  
  String? _selectedAction;
  String? _selectedEntityType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  final List<String> _actions = ['CREATE', 'UPDATE', 'DELETE', 'RESTORE', 'UPLOAD_ATTACHMENT', 'DELETE_ATTACHMENT', 'UPDATE_VALUES'];
  final List<String> _entityTypes = ['EVENT', 'CALENDAR', 'GROUP', 'CUSTOMFIELD', 'MEMBER', 'EVENTATTACHMENT'];

  @override
  void dispose() {
    _searchController.dispose();
    _usernameController.dispose();
    _entityIdController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().minus(const Duration(days: 7)),
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

  void _applyFilters() {
    ref.read(timetreeAuditLogsProvider.notifier).updateFilters(
      username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      action: _selectedAction,
      entityType: _selectedEntityType,
      entityId: _entityIdController.text.trim().isEmpty ? null : _entityIdController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      clearUsername: _usernameController.text.trim().isEmpty,
      clearAction: _selectedAction == null,
      clearEntityType: _selectedEntityType == null,
      clearEntityId: _entityIdController.text.trim().isEmpty,
      clearStartDate: _startDate == null,
      clearEndDate: _endDate == null,
      clearSearch: _searchController.text.trim().isEmpty,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _usernameController.clear();
      _entityIdController.clear();
      _selectedAction = null;
      _selectedEntityType = null;
      _startDate = null;
      _endDate = null;
    });
    ref.read(timetreeAuditLogsProvider.notifier).updateFilters(
      clearUsername: true,
      clearAction: true,
      clearEntityType: true,
      clearEntityId: true,
      clearStartDate: true,
      clearEndDate: true,
      clearSearch: true,
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ref.read(timetreeAuditLogsProvider.notifier).downloadCsv();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/audit_logs_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logs d\'audit exportés avec succès !\nSauvegardé dans: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'exportation CSV: $e'), backgroundColor: Colors.red),
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

    // Guard screen with admin check
    if (user == null || (user.role.toUpperCase() != 'ADMIN' && user.role.toUpperCase() != 'ADMINISTRATEUR')) {
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
                'Accès réservé aux administrateurs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Vous n\'avez pas les droits requis pour afficher ce journal d\'audit.'),
            ],
          ),
        ),
      );
    }

    final logsState = ref.watch(timetreeAuditLogsProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('TimeTree – Journal d\'Audit'),
        elevation: 0,
        actions: [
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
            onPressed: () => ref.read(timetreeAuditLogsProvider.notifier).loadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel Card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              leading: Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary),
              title: const Text('Filtres de recherche', style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Filtre textuel',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Utilisateur',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEntityType,
                        decoration: const InputDecoration(labelText: 'Type d\'entité'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tous')),
                          ..._entityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedEntityType = val);
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
                      child: TextField(
                        controller: _entityIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID d\'entité',
                          prefixIcon: Icon(Icons.fingerprint_rounded),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('Réinitialiser'),
                      onPressed: _clearAllFilters,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Rechercher'),
                      onPressed: _applyFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Audit Logs List View
          Expanded(
            child: logsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Erreur: ${logsState.error}', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.read(timetreeAuditLogsProvider.notifier).loadLogs(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : logsState.logs.isEmpty
                        ? const Center(child: Text('Aucun log d\'audit trouvé'))
                        : ListView.builder(
                            itemCount: logsState.logs.length,
                            itemBuilder: (context, index) {
                              final logItem = logsState.logs[index];
                              return _AuditLogTile(logItem: logItem);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.logItem});

  final TimetreeAuditLog logItem;

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
      case 'UPDATE_VALUES':
        return Colors.orange;
      case 'DELETE':
      case 'DELETE_ATTACHMENT':
        return Colors.red;
      case 'RESTORE':
        return Colors.blue;
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
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _actionColor(logItem.action).withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(logItem.username ?? 'Système', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(width: 12),
                Icon(Icons.fingerprint_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${logItem.entityType} ID: ${logItem.entityId ?? 'N/A'}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(fmtDate, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(width: 12),
                Icon(Icons.computer_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(logItem.ipAddress ?? '0.0.0.0', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime minus(Duration duration) => subtract(duration);
}
