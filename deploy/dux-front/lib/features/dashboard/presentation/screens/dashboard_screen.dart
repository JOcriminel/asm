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

/// Pure UI screen — all KPI computation is delegated to [GetDashboardStatsUseCase].
/// The build() method contains zero business logic (Single Responsibility).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _statsUseCase = GetDashboardStatsUseCase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final commandsState = ref.watch(commandsControllerProvider);
    final commands = commandsState.commands;

    // All computation delegated — screen has no business logic
    final stats = _statsUseCase(commands);

    final formattedRevenue = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'TND',
      decimalDigits: 3,
    ).format(stats.totalAmountTTC);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () =>
                ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true),
          ),
        ],
      ),
      body: commandsState.isLoading && commands.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Aperçu (Données chargées)'),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Total Commandes',
                          value: stats.totalCommands.toString(),
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
                  if (stats.totalCommands == 0)
                    const Center(child: Text('Aucune donnée à afficher'))
                  else
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (stats.pending > 0)
                              PieChartSectionData(
                                value: stats.pending.toDouble(),
                                title: '${stats.pending}',
                                color: Colors.orange,
                                radius: 50,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            if (stats.validated > 0)
                              PieChartSectionData(
                                value: stats.validated.toDouble(),
                                title: '${stats.validated}',
                                color: Colors.blue,
                                radius: 50,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            if (stats.delivered > 0)
                              PieChartSectionData(
                                value: stats.delivered.toDouble(),
                                title: '${stats.delivered}',
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
                  if (stats.totalCommands > 0) ...[
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
                  AppSpacing.gapXxl,
                ],
              ),
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
