import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/bon_preparation/presentation/screens/bon_preparation_list_screen.dart';
import 'package:dux_front/features/checklist/presentation/controllers/checklist_response_controller.dart';

class DynamicDocumentListScreen extends ConsumerStatefulWidget {
  final String docType;
  const DynamicDocumentListScreen({super.key, required this.docType});

  @override
  ConsumerState<DynamicDocumentListScreen> createState() => _DynamicDocumentListScreenState();
}

class _DynamicDocumentListScreenState extends ConsumerState<DynamicDocumentListScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _allDocuments = [];
  List<dynamic> _filteredDocuments = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _fetchDocuments();
  }

  @override
  void didUpdateWidget(covariant DynamicDocumentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docType != widget.docType) {
      _fetchDocuments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final authState = ref.read(authControllerProvider);

      final formatter = DateFormat('yyyy-MM-dd');
      final fromStr = formatter.format(_startDate);
      final toStr = '${formatter.format(_endDate)} 23:59:59'; // DUX ERP requires time suffix
      
      final idTierStr = authState.user?.id != null && authState.user!.id.isNotEmpty ? authState.user!.id : 'all';
      final represStr = authState.user?.tierId != null && authState.user!.tierId.isNotEmpty ? authState.user!.tierId : 'all';
      final codeDocStr = widget.docType;
      final idEtatStr = _selectedStatus;
      const allStr = 'false';
      const allDocsStr = 'false';
      const idArticleStr = 'null';
      const affichAvancStr = 'false';

      final path = '/list-documents/'
          '$fromStr/'
          '$toStr/'
          '$idTierStr/'
          '$represStr/'
          '$codeDocStr/'
          '$idEtatStr/'
          '$allStr/'
          '$allDocsStr/'
          '$idArticleStr/'
          '$affichAvancStr';

      final requestBody = {
        'idDocCommercial': [],
        'idTierModal': null,
        'event': {
          'first': 0,
          'rows': 500,
          'sortOrder': 1,
          'filters': {},
          'globalFilter': null
        }
      };

      final stationId = authState.user?.station;
      final response = await dio.post(
        path,
        data: requestBody,
        queryParameters: stationId != null && stationId.isNotEmpty && stationId != 'Default Station'
            ? {'stationId': stationId}
            : null,
      );

      if (response.data != null) {
        dynamic data = response.data;
        if (data is String && data.trim().isNotEmpty) {
          data = json.decode(data.trim());
        }

        List<dynamic> rawList = [];
        if (data is Map<String, dynamic>) {
          final status = data['status']?.toString();
          if (status == 'error') {
            throw Exception(data['data']?.toString() ?? 'Erreur API');
          }
          final inner = data['data'] ?? data['content'] ?? data['results'] ?? data['documents'];
          if (inner is List) {
            rawList = inner;
          } else {
            rawList = [data];
          }
        } else if (data is List) {
          rawList = data;
        }

        if (mounted) {
          setState(() {
            _allDocuments = rawList;
            _applyFilter();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allDocuments = [];
            _filteredDocuments = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getCardFields(String? configStr) {
    if (configStr == null || configStr.isEmpty) {
      return ['date', 'status'];
    }
    try {
      final parsed = jsonDecode(configStr);
      if (parsed is List) {
        return parsed.map((e) => e.toString()).toList();
      }
    } catch (_) {
      return configStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return ['date', 'status'];
  }

  List<String> _getSearchFields(String? configStr) {
    if (configStr == null || configStr.isEmpty) {
      return ['code', 'customer', 'representative'];
    }
    try {
      final parsed = jsonDecode(configStr);
      if (parsed is List) {
        return parsed.map((e) => e.toString()).toList();
      }
    } catch (_) {
      return configStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return ['code', 'customer', 'representative'];
  }

  void _applyFilter() {
    final config = ref.read(screenConfigControllerProvider).configs[widget.docType];
    if (_searchQuery.isEmpty) {
      _filteredDocuments = List.from(_allDocuments);
    } else {
      final query = _searchQuery.toLowerCase();
      final searchFields = _getSearchFields(config?.searchFieldsConfig);
      _filteredDocuments = _allDocuments.where((doc) {
        bool matches = false;
        if (searchFields.contains('code')) {
          final code = (doc['code'] ?? doc['documentCode'] ?? doc['codeDoc'] ?? doc['numDoc'] ?? '').toString().toLowerCase();
          if (code.contains(query)) matches = true;
        }
        if (searchFields.contains('customer')) {
          final tier = (doc['raisonSociale'] ?? doc['nomPrenomTier'] ?? doc['nomTier'] ?? doc['customerName'] ?? doc['tierName'] ?? '').toString().toLowerCase();
          if (tier.contains(query)) matches = true;
        }
        if (searchFields.contains('representative')) {
          final rep = (doc['nomPrenomRep'] ?? doc['RepDoc'] ?? doc['representative'] ?? '').toString().toLowerCase();
          if (rep.contains(query)) matches = true;
        }
        return matches;
      }).toList();
    }

    // Sort documents based on config defaultSortField setting
    final defaultSortField = config?.defaultSortField ?? 'date';

    if (defaultSortField == 'date') {
      _filteredDocuments.sort((a, b) {
        final dateA = _parseDate(a['dateDocument'] ?? a['dateSaisie'] ?? a['dateCreation'] ?? a['date']);
        final dateB = _parseDate(b['dateDocument'] ?? b['dateSaisie'] ?? b['dateCreation'] ?? b['date']);
        return dateB.compareTo(dateA); // Descending (newest first)
      });
    } else if (defaultSortField == 'code') {
      _filteredDocuments.sort((a, b) {
        final codeA = (a['code'] ?? a['documentCode'] ?? a['codeDoc'] ?? a['numDoc'] ?? '').toString().toLowerCase();
        final codeB = (b['code'] ?? b['documentCode'] ?? b['codeDoc'] ?? b['numDoc'] ?? '').toString().toLowerCase();
        return codeA.compareTo(codeB); // Ascending
      });
    } else if (defaultSortField == 'status') {
      _filteredDocuments.sort((a, b) {
        final statusA = (a['libelleEtatDoc'] ?? a['libelleEtat'] ?? a['status'] ?? '').toString().toLowerCase();
        final statusB = (b['libelleEtatDoc'] ?? b['libelleEtat'] ?? b['status'] ?? '').toString().toLowerCase();
        return statusA.compareTo(statusB); // Ascending
      });
    }
  }

  DateTime _parseDate(dynamic rawDate) {
    if (rawDate == null) return DateTime(1970);
    try {
      return DateTime.parse(rawDate.toString());
    } catch (_) {
      return DateTime(1970);
    }
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> doc) {
    final docId = (doc['idDocCommercial'] ?? doc['id'] ?? '').toString();
    if (docId.isEmpty) return;

    final type = widget.docType.toUpperCase();
    if (type.startsWith('BS') || type == 'BON_SORTIE') {
      context.push('/pages/bon-sortie/detail/$docId');
    } else if (type == 'BPR' || type == 'BON_RESERVATION') {
      context.push('/pages/bon-reservation/detail/$docId');
    } else if (type.startsWith('BP') || type.startsWith('PR') || type == 'BON_PREPARATION') {
      context.push('/pages/bon-preparation/detail/$docId?type=$type');
    } else {
      context.push('/commands/details/$docId');
    }
  }

  Color _getStatusColor(String? status, String configColorHex) {
    if (status == null || status.isEmpty) return Colors.grey;
    final s = status.toLowerCase();
    if (s.contains('valide') || s.contains('terminer') || s.contains('livr')) {
      return Colors.green;
    }
    if (s.contains('encours') || s.contains('prepar')) {
      return Colors.orange;
    }
    if (s.contains('annul') || s.contains('rejet')) {
      return Colors.red;
    }
    
    // Fallback to config primary color if valid hex
    try {
      final cleaned = configColorHex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Widget _buildDateRangePickerRow(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    if (_endDate.isBefore(_startDate)) {
                      _endDate = _startDate;
                    }
                  });
                  _fetchDocuments();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Début', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(formatter.format(_startDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                  _fetchDocuments();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fin', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(formatter.format(_endDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);
    final config = configState.configs[widget.docType];
    final title = config?.pageTitle ?? widget.docType;
    final primaryColorHex = config?.primaryColor ?? '#2196F3';
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toLowerCase() ?? '';
    final isOperator = userRole == 'operateur' || userRole == 'opérateur';
    final hidePrices = (config?.hidePrices ?? false) ||
                       ((config?.hidePricesForOperateurs ?? false) && isOperator) ||
                       (config?.hidePricesForRoles.any((r) => r.trim().toLowerCase() == userRole) ?? false);

    final showSN = config?.enableSerialNumberTracking ?? false;
    final isChecklistEnabled = config?.enableChecklistTracking ?? false;
    
    Color primaryColor = Colors.blue;
    try {
      final cleaned = primaryColorHex.replaceAll('#', '');
      primaryColor = Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {}

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: DuxAppBarTitle(title: title),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: config?.searchHint ?? 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilter();
                });
              },
            ),
          ),
          _buildDateRangePickerRow(context),
          _buildStatusFiltersRow(theme, config),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur : $_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchDocuments,
                                child: const Text('Réessayer'),
                              )
                            ],
                          ),
                        ),
                      )
                    : _filteredDocuments.isEmpty
                        ? const Center(
                            child: Text('Aucun document trouvé'),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchDocuments,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                              itemCount: _filteredDocuments.length,
                              itemBuilder: (context, index) {
                                final doc = _filteredDocuments[index] as Map<String, dynamic>;
                                final cardFields = _getCardFields(config?.cardFieldsConfig);
                                final code = doc['code'] ?? doc['documentCode'] ?? doc['codeDoc'] ?? doc['numDoc'] ?? 'Sans code';
                                final tier = doc['raisonSociale'] ?? doc['nomPrenomTier'] ?? doc['nomTier'] ?? doc['customerName'] ?? doc['tierName'] ?? 'Client inconnu';
                                final docId = (doc['idDocCommercial'] ?? doc['id'] ?? '').toString();
                                
                                String dateStr = '';
                                final rawDate = doc['dateDocument'] ?? doc['dateSaisie'] ?? doc['dateCreation'] ?? doc['date'];
                                if (rawDate != null) {
                                  try {
                                    final date = DateTime.parse(rawDate.toString());
                                    dateStr = DateFormat('dd/MM/yyyy').format(date);
                                  } catch (_) {
                                    dateStr = rawDate.toString();
                                  }
                                }

                                final amount = double.tryParse(doc['mntTtc']?.toString() ?? doc['amountTTC']?.toString() ?? doc['amount']?.toString() ?? doc['mntNetht']?.toString() ?? '0') ?? 0.0;
                                final formattedAmount = NumberFormat.currency(
                                  locale: 'fr_TN',
                                  symbol: 'TND',
                                  decimalDigits: 3,
                                ).format(amount);

                                final status = doc['libelleEtatDoc'] ?? doc['libelleEtat'] ?? doc['status'] ?? '';
                                final statusColor = _getStatusColor(status, primaryColorHex);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _navigateToDetail(context, doc),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.l),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                code.toString(),
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (status.isNotEmpty && cardFields.contains('status'))
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    status.toString(),
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: statusColor,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tier.toString(),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          if (cardFields.contains('representative')) ...[
                                            (() {
                                              final repName = doc['nomPrenomRep'] ?? doc['RepDoc'] ?? doc['representative'] ?? '';
                                              if (repName.toString().isNotEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        repName.toString(),
                                                        style: theme.textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            })(),
                                          ],
                                          if (cardFields.contains('station')) ...[
                                            (() {
                                              final stationName = doc['stationName'] ?? doc['nomStation'] ?? doc['nomStationCommercial'] ?? doc['station'] ?? '';
                                              if (stationName.toString().isNotEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.storefront_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        stationName.toString(),
                                                        style: theme.textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            })(),
                                          ],
                                          if (showSN || isChecklistEnabled) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                if (showSN)
                                                  Consumer(
                                                    builder: (context, ref, child) {
                                                      final snCountAsync = ref.watch(snCountProvider(docId));
                                                      return snCountAsync.when(
                                                        data: (updatedPrep) {
                                                          if (updatedPrep == null) return const SizedBox.shrink();
                                                          final scanned = updatedPrep.totalScannedSerialNumbers;
                                                          final required = updatedPrep.totalRequiredSerialNumbers;
                                                          final isComplete = scanned == required && required > 0;
                                                          final isOverscan = scanned > required;
                                                          Color bgColor = Colors.orange.shade50;
                                                          Color borderColor = Colors.orange.shade300;
                                                          Color textColor = Colors.orange.shade700;
                                                          if (isOverscan) {
                                                            bgColor = Colors.red.shade50;
                                                            borderColor = Colors.red.shade300;
                                                            textColor = Colors.red.shade700;
                                                          } else if (isComplete) {
                                                            bgColor = Colors.green.shade50;
                                                            borderColor = Colors.green.shade300;
                                                            textColor = Colors.green.shade700;
                                                          }
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: bgColor,
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(color: borderColor),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  isOverscan ? Icons.warning_amber_rounded : Icons.qr_code_scanner, 
                                                                  size: 14, 
                                                                  color: textColor
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'SN: $scanned / $required',
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                                        error: (_, _) => const SizedBox.shrink(),
                                                      );
                                                    },
                                                  ),
                                                if (isChecklistEnabled)
                                                  Consumer(
                                                    builder: (context, ref, child) {
                                                      final countAsync = ref.watch(documentChecklistCountProvider('$docId:${widget.docType}'));
                                                      return countAsync.when(
                                                        data: (count) {
                                                          if (count.total == 0) return const SizedBox.shrink();
                                                          final checked = count.checked;
                                                          final total = count.total;
                                                          final isComplete = checked == total && total > 0;
                                                          Color bgColor = checked == 0
                                                              ? Colors.red.shade50
                                                              : (isComplete ? Colors.green.shade50 : Colors.orange.shade50);
                                                          Color borderColor = checked == 0
                                                              ? Colors.red.shade300
                                                              : (isComplete ? Colors.green.shade300 : Colors.orange.shade300);
                                                          Color textColor = checked == 0
                                                              ? Colors.red.shade700
                                                              : (isComplete ? Colors.green.shade700 : Colors.orange.shade700);
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: bgColor,
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(color: borderColor),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  isComplete ? Icons.check_circle_outline : (checked == 0 ? Icons.playlist_add : Icons.playlist_add_check), 
                                                                  size: 14, 
                                                                  color: textColor
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  'Tasks ($checked/$total)',
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                                        error: (_, _) => const SizedBox.shrink(),
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (cardFields.contains('date'))
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      dateStr,
                                                      style: theme.textTheme.bodySmall,
                                                    ),
                                                  ],
                                                )
                                              else
                                                const SizedBox.shrink(),
                                               if (!hidePrices)
                                                Text(
                                                  formattedAmount,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFiltersRow(ThemeData theme, ScreenConfig? config) {
    final statusStr = config?.statusFilters;
    if (statusStr == null || statusStr.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Parse mapping
    final pairs = statusStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final options = <MapEntry<String, String>>[];
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        options.add(MapEntry(parts[0].trim(), parts[1].trim()));
      }
    }
    
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: AppSpacing.s, top: AppSpacing.xs),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = _selectedStatus == option.key || (_selectedStatus.isEmpty && option.key == 'all');
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                option.value,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = option.key;
                  });
                  _fetchDocuments();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
