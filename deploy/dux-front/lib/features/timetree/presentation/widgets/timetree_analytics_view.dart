import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';

class TimetreeAnalyticsView extends ConsumerWidget {
  final List<TimetreeEvent> events;
  final List<TimetreeCalendar> calendars;

  const TimetreeAnalyticsView({
    super.key,
    required this.events,
    required this.calendars,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final selectedMonth = ref.watch(currentCalendarDateProvider);
    // Filter events to only keep those that overlap with the selected month
    final monthlyEvents = events.where((e) {
      return (e.startDate.year == selectedMonth.year && e.startDate.month == selectedMonth.month) ||
             (e.endDate.year == selectedMonth.year && e.endDate.month == selectedMonth.month);
    }).toList();

    // Calculate metrics
    final totalCount = monthlyEvents.length;
    final completedCount = monthlyEvents.where((e) => e.status == 'COMPLETED').length;
    final inProgressCount = monthlyEvents.where((e) => e.status == 'IN_PROGRESS').length;
    final criticalCount = monthlyEvents.where((e) => e.priority == 'CRITICAL' || e.priority == 'HIGH').length;

    // Grouping by status
    final statusCounts = {
      'À Faire': monthlyEvents.where((e) => e.status == 'PLANNED' || e.status == 'DRAFT').length,
      'En Cours': inProgressCount,
      'Terminées': completedCount,
      'Annulées': monthlyEvents.where((e) => e.status == 'CANCELLED').length,
    };

    // Grouping by priority
    final priorityCounts = {
      'Basse': monthlyEvents.where((e) => e.priority == 'LOW').length,
      'Normale': monthlyEvents.where((e) => e.priority == 'NORMAL').length,
      'Haute': events.where((e) => e.priority == 'HIGH').length,
      'Urgente': events.where((e) => e.priority == 'CRITICAL').length,
    };

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: totalCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune donnée disponible pour les statistiques.',
                    style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. KPI Stats Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: "Total",
                          value: "$totalCount",
                          color: Colors.blueAccent,
                          icon: Icons.assignment_rounded,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: "Terminées",
                          value: "$completedCount",
                          color: Colors.green,
                          icon: Icons.check_circle_rounded,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: "En Cours",
                          value: "$inProgressCount",
                          color: Colors.orangeAccent,
                          icon: Icons.hourglass_top_rounded,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: "Urgentes/Hautes",
                          value: "$criticalCount",
                          color: Colors.redAccent,
                          icon: Icons.error_rounded,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Status Pie Chart
                  _buildChartCard(
                    title: "RÉPARTITION PAR STATUT",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 32,
                                sections: _buildPieSections(statusCounts),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem("À Faire", Colors.blueAccent, statusCounts['À Faire']!, totalCount),
                              _buildLegendItem("En Cours", Colors.orangeAccent, statusCounts['En Cours']!, totalCount),
                              _buildLegendItem("Terminées", Colors.green, statusCounts['Terminées']!, totalCount),
                              _buildLegendItem("Annulées", Colors.redAccent, statusCounts['Annulées']!, totalCount),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Priority Bar Chart
                  _buildChartCard(
                    title: "RÉPARTITION PAR PRIORITÉ",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(priorityCounts) * 1.25,
                          barTouchData: BarTouchData(enabled: true),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final style = TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  );
                                  switch (value.toInt()) {
                                    case 0:
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Basse', style: style),
                                      );
                                    case 1:
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Normale', style: style),
                                      );
                                    case 2:
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Haute', style: style),
                                      );
                                    case 3:
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Urgente', style: style),
                                      );
                                    default:
                                      return const Text('');
                                  }
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            _buildBarGroup(0, priorityCounts['Basse']!.toDouble(), Colors.teal),
                            _buildBarGroup(1, priorityCounts['Normale']!.toDouble(), Colors.blueGrey),
                            _buildBarGroup(2, priorityCounts['Haute']!.toDouble(), Colors.deepOrangeAccent),
                            _buildBarGroup(3, priorityCounts['Urgente']!.toDouble(), Colors.redAccent),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Color cardColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.6),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> data) {
    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.green,
      Colors.redAccent,
    ];
    final values = data.values.toList();
    final total = values.fold<int>(0, (sum, val) => sum + val);

    if (total == 0) return [];

    return List.generate(data.length, (i) {
      final val = values[i];
      final percentage = (val / total) * 100;
      return PieChartSectionData(
        value: val.toDouble(),
        title: val > 0 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: colors[i],
        radius: 36,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegendItem(String name, Color color, int count, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "$count (${percentage.toStringAsFixed(0)}%)",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  double _getMaxY(Map<String, int> priorityCounts) {
    double max = 0;
    for (var val in priorityCounts.values) {
      if (val > max) max = val.toDouble();
    }
    return max == 0 ? 10 : max;
  }
}
