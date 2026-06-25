import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_dashboard.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_dashboard_provider.dart';

class TimetreeDashboardScreen extends ConsumerWidget {
  const TimetreeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(timetreeDashboardProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('TimeTree – Tableau de bord'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(timetreeDashboardProvider),
          ),
        ],
      ),
      body: asyncDashboard.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(timetreeDashboardProvider),
        ),
        data: (dashboard) => _DashboardBody(dashboard: dashboard),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du tableau de bord…'),
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
              Icons.cloud_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger le tableau de bord',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final TimetreeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Handled via pull to refresh
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stat cards ─────────────────────────────────────────────
                _StatCardRow(dashboard: dashboard),
                const SizedBox(height: 20),

                // ── Calendar Utilization ────────────────────────────────────
                _UtilizationCard(utilization: dashboard.calendarUtilization),
                const SizedBox(height: 20),

                // ── Events by Status & Priority ─────────────────────────────
                _StatusPrioritySection(dashboard: dashboard),
                const SizedBox(height: 20),

                // ── Upcoming Events ─────────────────────────────────────────
                _UpcomingEventsSection(upcoming: dashboard.upcomingEvents),
                const SizedBox(height: 20),

                // ── Recent activities ───────────────────────────────────────
                _SectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Activités récentes',
                  count: dashboard.recentActivities.length,
                ),
                const SizedBox(height: 12),
                if (dashboard.recentActivities.isEmpty)
                  const _EmptyActivities()
                else
                  ...dashboard.recentActivities
                      .map((a) => _ActivityTile(activity: a)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.dashboard});

  final TimetreeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Catégories',
            value: dashboard.categoriesCount,
            icon: Icons.category_outlined,
            color: const Color(0xFF4F8EF7),
            onTap: () => context.go('/timetree/categories'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pages',
            value: dashboard.pagesCount,
            icon: Icons.insert_drive_file_outlined,
            color: const Color(0xFF43C89E),
            onTap: () => context.go('/timetree/pages'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilizationCard extends StatelessWidget {
  const _UtilizationCard({required this.utilization});

  final double utilization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: utilization / 100.0,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                  Center(
                    child: Text(
                      '${utilization.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilisation du calendrier',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pourcentage de jours occupés par des événements dans les 30 prochains jours.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPrioritySection extends StatelessWidget {
  const _StatusPrioritySection({required this.dashboard});

  final TimetreeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    final children = [
      _ChartCard(
        title: 'Événements par Statut',
        data: dashboard.eventsByStatus,
        colors: const {
          'DRAFT': Colors.grey,
          'PLANNED': Colors.blue,
          'IN_PROGRESS': Colors.orange,
          'COMPLETED': Colors.green,
          'CANCELLED': Colors.red,
        },
      ),
      if (!isWide) const SizedBox(height: 16) else const SizedBox(width: 16),
      _ChartCard(
        title: 'Événements par Priorité',
        data: dashboard.eventsByPriority,
        colors: const {
          'LOW': Colors.green,
          'NORMAL': Colors.blue,
          'HIGH': Colors.orange,
          'CRITICAL': Colors.red,
        },
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((w) => w is SizedBox ? w : Expanded(child: w)).toList(),
      );
    } else {
      return Column(
        children: children,
      );
    }
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.data,
    required this.colors,
  });

  final String title;
  final Map<String, int> data;
  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.values.fold(0, (sum, item) => sum + item);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Aucune donnée')),
              )
            else
              ...data.entries.map((entry) {
                final count = entry.value;
                final percentage = total > 0 ? (count / total) : 0.0;
                final color = colors[entry.key] ?? Colors.blueGrey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection({required this.upcoming});

  final List<TimetreeUpcomingEvent> upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Événements à venir (7 prochains jours)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Aucun événement à venir')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcoming.length,
                itemBuilder: (context, index) {
                  final ev = upcoming[index];
                  final fmtDate = DateFormat('dd MMM yyyy – HH:mm').format(ev.startDate);
                  final color = ev.color != null ? Color(int.parse(ev.color!.replaceFirst('#', 'FF'), radix: 16)) : theme.colorScheme.primary;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: color, width: 4)),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        ev.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(fmtDate),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveEntitiesSection extends StatelessWidget {
  const _ActiveEntitiesSection({required this.dashboard});

  final TimetreeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Groupes les plus actifs',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.mostActiveGroups.isEmpty)
                    const Text('Aucun groupe actif')
                  else
                    ...dashboard.mostActiveGroups.map((g) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Chip(label: Text('${g.eventCount} évts'), visualDensity: VisualDensity.compact),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membres les plus actifs',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.mostActiveMembers.isEmpty)
                    const Text('Aucun membre actif')
                  else
                    ...dashboard.mostActiveMembers.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Chip(label: Text('${m.eventCount} part.'), visualDensity: VisualDensity.compact),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Chip(
            label: Text('$count'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final TimetreeActivity activity;

  static final _dateFormat = DateFormat('dd MMM yyyy – HH:mm');

  String _formatDate(DateTime? dt) {
    if (dt == null) return '–';
    try {
      return _dateFormat.format(dt.toLocal());
    } catch (_) {
      return dt.toLocal().toString();
    }
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'CATEGORY_CREATED':
      case 'CREATE':
        return Icons.add_box_outlined;
      case 'CATEGORY_UPDATED':
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'CATEGORY_DELETED':
      case 'DELETE':
        return Icons.delete_outline;
      case 'PAGE_CREATED':
        return Icons.note_add_outlined;
      case 'PAGE_UPDATED':
        return Icons.drive_file_rename_outline;
      case 'PAGE_DELETED':
        return Icons.delete_sweep_outlined;
      case 'GROUP_CREATED':
        return Icons.group_add_outlined;
      case 'GROUP_UPDATED':
        return Icons.manage_accounts_outlined;
      case 'GROUP_DELETED':
        return Icons.group_remove_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _iconForType(activity.type),
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          activity.title.isNotEmpty ? activity.title : activity.type,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(activity.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune activité récente',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
