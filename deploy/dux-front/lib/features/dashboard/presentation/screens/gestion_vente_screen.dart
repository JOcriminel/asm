import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/routing/page_route_registry.dart';

class GestionVenteScreen extends ConsumerWidget {
  final String categoryName;
  const GestionVenteScreen({super.key, this.categoryName = 'Gestion de Vente'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);

    if (configState.isLoading) {
      return const DuxLoadingScreen(isFullScreen: true);
    }

    final configs = configState.configs;

    final List<Map<String, dynamic>> menuItems = [];

    // Add configured active pages that are mapped to this category
    final isCategoryActive = configState.categories
        .any((c) => c.name == categoryName && c.active);
    configs.forEach((key, config) {
      if (config.category == categoryName && config.isActive && isCategoryActive) {
        IconData icon;
        String route;

        final reg = pageRouteRegistry[key];
        if (reg != null) {
          icon = reg.icon;
          route = reg.pathToGo;
        } else {
          icon = Icons.assignment_rounded;
          route = '/pages/dynamic-list/$key';
        }

        Color primaryColor = theme.colorScheme.primary;
        try {
          final cleaned = config.primaryColor.replaceAll('#', '');
          primaryColor = Color(int.parse('FF$cleaned', radix: 16));
        } catch (_) {}

        menuItems.add({
          'title': config.pageTitle,
          'icon': icon,
          'route': route,
          'color': primaryColor,
        });
      }
    });

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: Text(categoryName),
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
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          ),
        ],
      ),
      body: menuItems.isEmpty
          ? const Center(
              child: Text(
                'Aucun écran disponible sous Gestion de Vente.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          : GridView.builder(
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
                  color: item['color'] as Color? ?? theme.colorScheme.primary,
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
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
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
              color: color,
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
