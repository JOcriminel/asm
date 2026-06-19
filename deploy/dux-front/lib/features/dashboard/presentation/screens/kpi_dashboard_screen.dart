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
import 'package:dux_front/features/dashboard/domain/usecases/get_dashboard_stats_use_case.dart';
import 'package:dux_front/features/dashboard/presentation/controllers/dashboard_controller.dart';

/// Pure UI screen — all KPI computation is delegated to [GetDashboardStatsUseCase].
/// The build() method contains zero business logic (Single Responsibility).
class KpiDashboardScreen extends ConsumerStatefulWidget {
  const KpiDashboardScreen({super.key});

  @override
  ConsumerState<KpiDashboardScreen> createState() => _KpiDashboardScreenState();
}

class _KpiDashboardScreenState extends ConsumerState<KpiDashboardScreen> {
  static const _statsUseCase = GetDashboardStatsUseCase();
  DateTimeRange? _selectedDateRange;
  String? _selectedOperator;
  String? _selectedDocType;

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
        _selectedDateRange = newRange;
      });
      ref.read(dashboardControllerProvider.notifier).fetchStats(
            startDate: newRange.start,
            endDate: newRange.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commandsState = ref.watch(commandsControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final commands = commandsState.commands;

    // Filter local commands by document type
    final filteredCommands = commands.where((cmd) {
      if (_selectedDocType != null) {
        final type = _selectedDocType!.toUpperCase();
        if (type == 'BC') {
          return cmd.documentTypeCode.contains('BC') || cmd.documentType.toLowerCase().contains('commande');
        } else if (type == 'BP') {
          return cmd.documentTypeCode.contains('BP') || cmd.documentType.toLowerCase().contains('préparation') || cmd.documentType.toLowerCase().contains('preparation');
        } else if (type == 'BS') {
          return cmd.documentTypeCode.contains('BS') || cmd.documentType.toLowerCase().contains('sortie');
        }
      }
      return true;
    }).toList();

    // Local Stats
    final localStats = _statsUseCase(filteredCommands);
    final formattedRevenue = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'TND',
      decimalDigits: 3,
    ).format(localStats.totalAmountTTC);

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
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Filtrer par date',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true);
              ref.read(dashboardControllerProvider.notifier).fetchStats(
                startDate: _selectedDateRange?.start,
                endDate: _selectedDateRange?.end,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(theme, dashboardState.stats?.operatorPerformance ?? []),
            AppSpacing.gapL,
            // ============================================
            // 1. SCAN PERFORMANCE (API)
            // ============================================
            SectionHeader(title: 'Performance de Scan ($dateText)'),
            _buildApiStats(context, dashboardState, theme),
            
            AppSpacing.gapXxl,

            // ============================================
            // 2. COMMAND OVERVIEW (LOCAL)
            // ============================================
            SectionHeader(title: 'Aperçu des Commandes'),
            if (commandsState.isLoading && commands.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Total Commandes',
                      value: localStats.totalCommands.toString(),
                      icon: Icons.assignment_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.gapL,
                  Expanded(
                    child: _KpiCard(
                      title: "Chiffre d'affaires",
                      value: formattedRevenue,
                      icon: Icons.payments_rounded,
                      color: Colors.green,
                      isSmallValue: true,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXxl,
              SectionHeader(title: 'Répartition par Statut'),
              if (localStats.totalCommands == 0)
                const Center(child: Text('Aucune donnée à afficher'))
              else
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (localStats.pending > 0)
                          PieChartSectionData(
                            value: localStats.pending.toDouble(),
                            title: '${localStats.pending}',
                            color: Colors.orange,
                            radius: 50,
                            titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        if (localStats.validated > 0)
                          PieChartSectionData(
                            value: localStats.validated.toDouble(),
                            title: '${localStats.validated}',
                            color: Colors.blue,
                            radius: 50,
                            titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        if (localStats.delivered > 0)
                          PieChartSectionData(
                            value: localStats.delivered.toDouble(),
                            title: '${localStats.delivered}',
                            color: Colors.green,
                            radius: 50,
                            titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              if (localStats.totalCommands > 0) ...[
                AppSpacing.gapM,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: Colors.orange, text: 'En attente'),
                    AppSpacing.gapM,
                    _LegendItem(color: Colors.blue, text: 'Validé'),
                    AppSpacing.gapM,
                    _LegendItem(color: Colors.green, text: 'Livré'),
                  ],
                ),
              ],
            ],
            AppSpacing.gapXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildApiStats(BuildContext context, DashboardState state, ThemeData theme) {
    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.stats == null) {
      return Center(child: Text('Erreur: ${state.error}', style: TextStyle(color: theme.colorScheme.error)));
    }

    final stats = state.stats;
    if (stats == null) return const SizedBox.shrink();

    int scansCount = stats.scansToday;
    int deletionsCount = stats.deletionsToday;
    if (_selectedOperator != null) {
      final op = stats.operatorPerformance.firstWhere(
        (o) => o['userId']?.toString() == _selectedOperator,
        orElse: () => <String, dynamic>{},
      );
      scansCount = (op['scans'] as num? ?? 0).toInt();
      deletionsCount = (op['deletions'] as num? ?? 0).toInt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Articles Scannés',
                value: scansCount.toString(),
                icon: Icons.qr_code_scanner,
                color: Colors.green,
              ),
            ),
            AppSpacing.gapL,
            Expanded(
              child: _KpiCard(
                title: 'Modifications',
                value: deletionsCount.toString(),
                icon: Icons.edit_note,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        


        AppSpacing.gapXxl,
        SectionHeader(
          title: _selectedOperator == null 
              ? 'Répartition Horaire' 
              : 'Répartition Horaire (Générale)',
        ),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: SizedBox(
            height: 250,
            child: stats.scansByHour.isEmpty
                ? Center(child: Text('Aucune activité enregistrée', style: theme.textTheme.bodyMedium))
                : _buildLineChart(theme, stats.scansByHour),
          ),
        ),

        AppSpacing.gapXxl,
        SectionHeader(
          title: _selectedOperator == null 
              ? 'Historique des Jours' 
              : 'Historique des Jours (Général)',
        ),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: SizedBox(
            height: 250,
            child: stats.scansLast7Days.isEmpty
                ? Center(child: Text('Aucune donnée disponible', style: theme.textTheme.bodyMedium))
                : _buildBarChart(theme, stats.scansLast7Days),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(ThemeData theme, List<Map<String, dynamic>> rawData) {
    List<FlSpot> spots = [];
    double maxY = 0;
    
    // Fill in a 24-hour map so we don't have gaps
    Map<int, double> hoursData = {};
    for (int i = 0; i < 24; i++) {
      hoursData[i] = 0.0;
    }
    
    for (var data in rawData) {
      int hour = (data['hour'] as num).toInt();
      double count = (data['count'] as num).toDouble();
      hoursData[hour] = count;
      if (count > maxY) maxY = count;
    }

    // Only show hours where there's some activity overall? Or just show 0 to 23.
    int minHour = 24;
    int maxHour = 0;
    hoursData.forEach((h, val) {
      if (val > 0) {
        if (h < minHour) minHour = h;
        if (h > maxHour) maxHour = h;
      }
    });

    if (minHour == 24) minHour = 8; // Default
    if (maxHour == 0) maxHour = 18; // Default
    minHour = (minHour - 1).clamp(0, 23);
    maxHour = (maxHour + 1).clamp(0, 23);

    for (int i = minHour; i <= maxHour; i++) {
      spots.add(FlSpot(i.toDouble(), hoursData[i]!));
    }

    return LineChart(
      LineChartData(
        minX: minHour.toDouble(),
        maxX: maxHour.toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.x.toInt()}h00\n${spot.y.toInt()} Scans',
                  TextStyle(color: theme.colorScheme.surface, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              strokeWidth: 1,
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
              interval: 2, // Every 2 hours
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == maxY * 1.2) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.35),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme, List<Map<String, dynamic>> rawData) {
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    
    for (int i = 0; i < rawData.length; i++) {
      final data = rawData[i];
      final count = (data['count'] ?? 0).toDouble();
      if (count > maxY) maxY = count;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                  theme.colorScheme.primary,
                ],
              ),
              width: 18,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = rawData[group.x.toInt()];
              final dateStr = data['date'];
              return BarTooltipItem(
                '$dateStr\n${rod.toY.toInt()} Scans',
                TextStyle(color: theme.colorScheme.surface, fontWeight: FontWeight.bold),
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
                final index = value.toInt();
                if (index < 0 || index >= rawData.length) return const SizedBox.shrink();
                
                final dateStr = rawData[index]['date'].toString();
                String shortDate = dateStr;
                try {
                  final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                  shortDate = DateFormat('dd/MM').format(date);
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortDate,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == maxY * 1.2) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
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
          horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        barGroups: barGroups,
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
              value: _selectedOperator ?? 'Tous',
              decoration: const InputDecoration(
                labelText: 'Opérateur',
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
              value: _selectedDocType ?? 'Tous',
              decoration: const InputDecoration(
                labelText: 'Document',
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

}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSmallValue;

  const _KpiCard({
    required this.title,
    required this.value,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          AppSpacing.gapM,
          Text(
            title,
            style:
                theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          AppSpacing.gapXs,
          Text(
            value,
            style: isSmallValue
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
