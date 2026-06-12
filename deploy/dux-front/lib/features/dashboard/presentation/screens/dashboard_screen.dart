import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/features/commands/presentation/controllers/commands_controller.dart';
import 'package:dux_front/features/commands/domain/models/command.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final commandsState = ref.watch(commandsControllerProvider);
    final commands = commandsState.commands;

    // Calculate KPIs
    final totalCommands = commands.length;
    final totalRevenue = commands.fold(0.0, (sum, cmd) => sum + cmd.amountTTC);
    
    // Status counts
    int pending = 0;
    int validated = 0;
    int delivered = 0;
    int cancelled = 0;
    int others = 0;

    for (var c in commands) {
      final s = c.status.toLowerCase();
      if (s.contains('pending') || s.contains('en attente')) {
        pending++;
      } else if (s.contains('valid') || s.contains('confirmé')) {
        validated++;
      } else if (s.contains('deliver') || s.contains('livré')) {
        delivered++;
      } else if (s.contains('cancel') || s.contains('annulé')) {
        cancelled++;
      } else {
        others++;
      }
    }

    final formattedRevenue = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'TND',
      decimalDigits: 3,
    ).format(totalRevenue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true),
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
                          value: totalCommands.toString(),
                          icon: Icons.assignment_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      AppSpacing.gapL,
                      Expanded(
                        child: _KpiCard(
                          title: 'Chiffre d\'affaires',
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
                  if (totalCommands == 0)
                    const Center(child: Text('Aucune donnée à afficher'))
                  else
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (pending > 0)
                              PieChartSectionData(
                                value: pending.toDouble(),
                                title: '$pending',
                                color: Colors.orange,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (validated > 0)
                              PieChartSectionData(
                                value: validated.toDouble(),
                                title: '$validated',
                                color: Colors.blue,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (delivered > 0)
                              PieChartSectionData(
                                value: delivered.toDouble(),
                                title: '$delivered',
                                color: Colors.green,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (cancelled > 0)
                              PieChartSectionData(
                                value: cancelled.toDouble(),
                                title: '$cancelled',
                                color: Colors.red,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (others > 0)
                              PieChartSectionData(
                                value: others.toDouble(),
                                title: '$others',
                                color: Colors.grey,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (totalCommands > 0) ...[
                    AppSpacing.gapM,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: Colors.orange, text: 'En attente'),
                        AppSpacing.gapM,
                        _LegendItem(color: Colors.blue, text: 'Validé'),
                        AppSpacing.gapM,
                        _LegendItem(color: Colors.green, text: 'Livré'),
                        AppSpacing.gapM,
                        _LegendItem(color: Colors.red, text: 'Annulé'),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          AppSpacing.gapM,
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary),
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
