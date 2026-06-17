import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'KPI\nDashboard', 'icon': Icons.dashboard_outlined, 'route': '/kpi-dashboard'},
      {'title': 'Bon De\nCommande', 'icon': Icons.receipt_long_outlined, 'route': '/commands'},
      {'title': 'Bon De\nPréparation', 'icon': Icons.precision_manufacturing_outlined, 'route': '/pages/bon-preparation/list'},
      {'title': 'Clients', 'icon': Icons.group_outlined, 'route': '/clients'},
      {'title': 'Journal\nd\'Activité', 'icon': Icons.history_outlined, 'route': '/activity-feed'},
      {'title': 'Station', 'icon': Icons.storefront_outlined, 'route': '/station'},
      {'title': 'Profil', 'icon': Icons.person_outline, 'route': '/profile'},
    ];

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('DUX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.home_outlined, color: theme.colorScheme.primary),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.l),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.m,
          mainAxisSpacing: AppSpacing.m,
          childAspectRatio: 0.85,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuCard(
            title: item['title'] as String,
            icon: item['icon'] as IconData,
            onTap: () {
              if (item['route'] != null) {
                context.go(item['route'] as String);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} non implémenté')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.onSurface,
            ),
            AppSpacing.gapM,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

