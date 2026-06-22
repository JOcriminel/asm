import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/commands/presentation/controllers/commands_controller.dart';
import 'package:dux_front/features/dashboard/presentation/controllers/dashboard_controller.dart';

class KpiDashboardScreen extends ConsumerStatefulWidget {
  const KpiDashboardScreen({super.key});

  @override
  ConsumerState<KpiDashboardScreen> createState() => _KpiDashboardScreenState();
}

class _KpiDashboardScreenState extends ConsumerState<KpiDashboardScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedOperator;
  String? _selectedDocType;
  String _selectedPeriod = 'TODAY'; // TODAY, WEEK, MONTH, YEAR, CUSTOM

  @override
  void initState() {
    super.initState();
    // Default to TODAY
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: now, end: now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStats();
    });
  }

  void _fetchStats() {
    ref.read(dashboardControllerProvider.notifier).fetchStats(
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
        );
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    final now = DateTime.now();
    DateTimeRange range;
    if (period == 'TODAY') {
      range = DateTimeRange(start: now, end: now);
    } else if (period == 'WEEK') {
      range = DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    } else if (period == 'MONTH') {
      range = DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now);
    } else if (period == 'YEAR') {
      range = DateTimeRange(start: now.subtract(const Duration(days: 365)), end: now);
    } else {
      _pickDateRange();
      return;
    }
    setState(() {
      _selectedDateRange = range;
    });
    _fetchStats();
  }

  void _pickDateRange() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedPeriod = 'CUSTOM';
        _selectedDateRange = newRange;
      });
      _fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardControllerProvider);

    String dateText = "Aujourd'hui";
    if (_selectedDateRange != null) {
      final start = DateFormat('dd/MM').format(_selectedDateRange!.start);
      final end = DateFormat('dd/MM').format(_selectedDateRange!.end);
      if (start == end) {
        dateText = "Le $start";
      } else {
        dateText = "Du $start au $end";
      }
    }

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true);
              _fetchStats();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(theme),
            AppSpacing.gapL,
            _buildFilterBar(theme, dashboardState.stats?.operatorPerformance ?? []),
            AppSpacing.gapL,
            SectionHeader(title: 'Performances & Activités ($dateText)'),
            _buildApiStats(context, dashboardState, theme),
            AppSpacing.gapXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    final periods = [
      {'id': 'TODAY', 'label': '1 Jour'},
      {'id': 'WEEK', 'label': '7 Jours'},
      {'id': 'MONTH', 'label': '30 Jours'},
      {'id': 'YEAR', 'label': '12 Mois'},
      {'id': 'CUSTOM', 'label': 'Perso'},
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectPeriod(p['id']!),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      p['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, List<Map<String, dynamic>> operators) {
    final operatorList = ['Tous', ...operators.map((o) => o['userId']?.toString() ?? 'Inconnu').toSet()];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedOperator ?? 'Tous',
              decoration: const InputDecoration(
                labelText: 'Filtrer Opérateur',
                labelStyle: TextStyle(fontSize: 12),
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                border: InputBorder.none,
              ),
              items: operatorList.map((op) => DropdownMenuItem(value: op, child: Text(op, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedOperator = val == 'Tous' ? null : val;
                });
              },
            ),
          ),
          Container(
            width: 1.5,
            height: 32,
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedDocType ?? 'Tous',
              decoration: const InputDecoration(
                labelText: 'Filtrer Document',
                labelStyle: TextStyle(fontSize: 12),
                prefixIcon: Icon(Icons.description_outlined, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                border: InputBorder.none,
              ),
              items: const [
                DropdownMenuItem(value: 'Tous', child: Text('Tous (BC/BP/BS)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'BC', child: Text('Bon de Commande', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'BP', child: Text('Bon de Préparation', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'BS', child: Text('Bon de Sortie', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedDocType = val == 'Tous' ? null : val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiStats(BuildContext context, DashboardState state, ThemeData theme) {
    if (state.isLoading && state.stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null && state.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'Erreur: ${state.error}',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    final stats = state.stats;
    if (stats == null) return const SizedBox.shrink();

    // 1. Filter local summary values based on operator selection
    int scansCount = stats.scansCount;
    int deletionsCount = stats.deletionsCount;
    int checklistCount = stats.checklistResponsesCount;
    double accuracy = stats.avgAccuracy;

    if (_selectedOperator != null) {
      final op = stats.operatorPerformance.firstWhere(
        (o) => o['userId']?.toString() == _selectedOperator,
        orElse: () => <String, dynamic>{},
      );
      scansCount = (op['scans'] as num? ?? 0).toInt();
      deletionsCount = (op['deletions'] as num? ?? 0).toInt();
      checklistCount = (op['checklists'] as num? ?? 0).toInt();
      accuracy = (op['accuracy'] as num? ?? 100.0).toDouble();
    }

    final formattedRevenue = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'TND',
      decimalDigits: 3,
    ).format(stats.totalRevenue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary Row 1
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Articles Scannés',
                value: scansCount.toString(),
                subValue: 'Précision: ${accuracy.toStringAsFixed(1)}%',
                icon: Icons.qr_code_scanner_rounded,
                color: Colors.green,
              ),
            ),
            AppSpacing.gapL,
            Expanded(
              child: _KpiCard(
                title: 'Tâches Validées',
                value: checklistCount.toString(),
                subValue: 'Suppression: $deletionsCount',
                icon: Icons.playlist_add_check_rounded,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        AppSpacing.gapL,
        // KPI Summary Row 2
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Total Commandes',
                value: stats.totalCommands.toString(),
                subValue: 'Flux ERP Activé',
                icon: Icons.assignment_rounded,
                color: Colors.purple,
              ),
            ),
            AppSpacing.gapL,
            Expanded(
              child: _KpiCard(
                title: "Chiffre d'affaires",
                value: formattedRevenue,
                subValue: 'Montant Global TTC',
                icon: Icons.payments_rounded,
                color: Colors.teal,
                isSmallValue: true,
              ),
            ),
          ],
        ),

        // Timeline Trend Line Chart
        AppSpacing.gapXxl,
        SectionHeader(title: 'Tendance des Activités (Scans & Checklists)'),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: SizedBox(
            height: 250,
            child: stats.timeline.isEmpty
                ? Center(child: Text('Aucune activité sur cette période', style: theme.textTheme.bodyMedium))
                : _buildTimelineLineChart(theme, stats.timeline),
          ),
        ),

        // Revenue Progression Bar Chart
        AppSpacing.gapXxl,
        SectionHeader(title: 'Évolution du Chiffre d\'affaires (TND)'),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: SizedBox(
            height: 250,
            child: stats.timeline.isEmpty
                ? Center(child: Text('Aucun montant enregistré', style: theme.textTheme.bodyMedium))
                : _buildRevenueBarChart(theme, stats.timeline),
          ),
        ),

        // Symmetrical Pie Charts Row
        AppSpacing.gapXxl,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  const SectionHeader(title: 'Docs par Type'),
                  InfoCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                    child: SizedBox(
                      height: 180,
                      child: stats.byType.isEmpty
                          ? const Center(child: Text('Néant', style: TextStyle(fontSize: 12)))
                          : _buildTypePieChart(theme, stats.byType),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapL,
            Expanded(
              child: Column(
                children: [
                  const SectionHeader(title: 'Docs par Statut'),
                  InfoCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                    child: SizedBox(
                      height: 180,
                      child: stats.byStatus.isEmpty
                          ? const Center(child: Text('Néant', style: TextStyle(fontSize: 12)))
                          : _buildStatusPieChart(theme, stats.byStatus),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Operator Performance Leaderboard
        AppSpacing.gapXxl,
        const SectionHeader(title: 'Leaderboard & Précision des Opérateurs'),
        _buildOperatorLeaderboardTable(theme, stats.operatorPerformance),
      ],
    );
  }

  Widget _buildTimelineLineChart(ThemeData theme, List<Map<String, dynamic>> timeline) {
    List<FlSpot> scanSpots = [];
    List<FlSpot> checklistSpots = [];
    double maxY = 0;

    for (int i = 0; i < timeline.length; i++) {
      final scans = (timeline[i]['scans'] as num? ?? 0).toDouble();
      final checklists = (timeline[i]['checklists'] as num? ?? 0).toDouble();
      scanSpots.add(FlSpot(i.toDouble(), scans));
      checklistSpots.add(FlSpot(i.toDouble(), checklists));

      if (scans > maxY) maxY = scans;
      if (checklists > maxY) maxY = checklists;
    }

    if (maxY == 0) maxY = 10;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (timeline.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.15,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isScan = spot.barIndex == 0;
                final label = timeline[spot.x.toInt()]['label'];
                return LineTooltipItem(
                  '$label\n${isScan ? "Scans" : "Checklists"}: ${spot.y.toInt()}',
                  TextStyle(color: theme.colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              strokeWidth: 0.8,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= timeline.length) return const SizedBox.shrink();
                final interval = (timeline.length / 5).ceil();
                if (idx % interval != 0 && idx != timeline.length - 1) return const SizedBox.shrink();

                return Text(
                  timeline[idx]['label'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.colorScheme.secondary),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == maxY * 1.15) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.colorScheme.secondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Scans Line (Green)
          LineChartBarData(
            spots: scanSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.green.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Checklists Line (Blue)
          LineChartBarData(
            spots: checklistSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBarChart(ThemeData theme, List<Map<String, dynamic>> timeline) {
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < timeline.length; i++) {
      final revenue = (timeline[i]['revenue'] as num? ?? 0.0).toDouble();
      if (revenue > maxY) maxY = revenue;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                  theme.colorScheme.primary,
                ],
              ),
              width: timeline.length > 15 ? 8 : 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    if (maxY == 0) maxY = 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = timeline[group.x.toInt()]['label'];
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(0)} TND',
                TextStyle(color: theme.colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= timeline.length) return const SizedBox.shrink();
                final interval = (timeline.length / 5).ceil();
                if (idx % interval != 0 && idx != timeline.length - 1) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    timeline[idx]['label'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.colorScheme.secondary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                if (value == maxY * 1.15) return const SizedBox.shrink();
                String formatted = value.toInt().toString();
                if (value >= 1000) {
                  formatted = '${(value / 1000).toStringAsFixed(1)}k';
                }
                return Text(
                  formatted,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: theme.colorScheme.secondary),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              strokeWidth: 0.8,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildTypePieChart(ThemeData theme, List<Map<String, dynamic>> byType) {
    final colors = [Colors.purple, Colors.orange, Colors.teal];
    double total = byType.fold(0.0, (sum, item) => sum + (item['count'] as num? ?? 0).toDouble());

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: List.generate(byType.length, (i) {
          final item = byType[i];
          final type = item['type']?.toString() ?? 'BC';
          final count = (item['count'] as num? ?? 0).toInt();
          final percentage = total > 0 ? (count / total) * 100 : 0.0;

          return PieChartSectionData(
            value: count.toDouble(),
            title: '$type\n${percentage.toStringAsFixed(0)}%',
            color: colors[i % colors.length],
            radius: 40,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
      ),
    );
  }

  Widget _buildStatusPieChart(ThemeData theme, List<Map<String, dynamic>> byStatus) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];
    double total = byStatus.fold(0.0, (sum, item) => sum + (item['count'] as num? ?? 0).toDouble());

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: List.generate(byStatus.length, (i) {
          final item = byStatus[i];
          final status = item['status']?.toString() ?? 'En attente';
          final count = (item['count'] as num? ?? 0).toInt();
          final percentage = total > 0 ? (count / total) * 100 : 0.0;

          String shortStatus = status;
          if (status.length > 8) {
            shortStatus = '${status.substring(0, 7)}.';
          }

          return PieChartSectionData(
            value: count.toDouble(),
            title: '$shortStatus\n${percentage.toStringAsFixed(0)}%',
            color: colors[i % colors.length],
            radius: 40,
            titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
      ),
    );
  }

  Widget _buildOperatorLeaderboardTable(ThemeData theme, List<Map<String, dynamic>> operators) {
    if (operators.isEmpty) {
      return InfoCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Aucune activité par opérateur enregistrée', style: TextStyle(fontSize: 12)),
          ),
        ),
      );
    }

    return InfoCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.6),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15), width: 1.5)),
            ),
            children: const [
              Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Opérateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Suppr.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Checklists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Précision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          ...operators.map((op) {
            final userId = op['userId']?.toString() ?? 'Inconnu';
            final scans = (op['scans'] as num? ?? 0).toInt();
            final deletions = (op['deletions'] as num? ?? 0).toInt();
            final checklists = (op['checklists'] as num? ?? 0).toInt();
            final accuracy = (op['accuracy'] as num? ?? 100.0).toDouble();

            return TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.08), width: 0.8)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(child: Text(userId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text('$scans', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text('$deletions', style: const TextStyle(fontSize: 11, color: Colors.orange))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text('$checklists', style: const TextStyle(fontSize: 11, color: Colors.blue))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accuracy >= 95 ? Colors.green : (accuracy >= 85 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;
  final bool isSmallValue;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    this.isSmallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InfoCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subValue,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.secondary),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapM,
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
          ),
          AppSpacing.gapXs,
          Text(
            value,
            style: isSmallValue
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)
                : theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
