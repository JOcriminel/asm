import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';

class DynamicScreensConfigScreen extends ConsumerWidget {
  const DynamicScreensConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);

    if (configState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Bon de\nCommande',
        'icon': Icons.receipt_long_rounded,
        'type': 'BC',
      },
      {
        'title': 'Bon de\nPréparation',
        'icon': Icons.inventory_2_outlined,
        'type': 'BP',
      },
      {
        'title': 'Bon de\nSortie',
        'icon': Icons.local_shipping_outlined,
        'type': 'BS',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Config Dynamique'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.l,
              bottom: AppSpacing.s,
            ),
            child: Text(
              'Sélectionnez l\'écran à configurer :',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.l),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                childAspectRatio: 0.76, // Adjusted from 0.85 to give more vertical space
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _ConfigMenuCard(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  onTap: () {
                    context.push('/admin/screen-settings/edit/${item['type']}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ConfigMenuCard({
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
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding to save vertical space
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24, // Reduced size from 28 to 24
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.gapM, // Reduced gap from gapL (12) to gapM (8)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5, // Reduced font size for better fit on small viewports
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
