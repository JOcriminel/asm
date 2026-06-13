import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_footer.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import 'package:dux_front/core/theme/theme_controller.dart';
import 'package:dux_front/features/profile/presentation/controllers/profile_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class DuxDrawer extends ConsumerWidget {
  const DuxDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final themeMode = ref.watch(themeControllerProvider);
    
    // Determine if we are currently in dark mode
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    Widget buildDrawerItem({
      required IconData icon,
      required String label,
      required String routeName,
      required String pathPrefix,
    }) {
      final isSelected = currentRoute.startsWith(pathPrefix);
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        onTap: () {
          Navigator.pop(context); // Close drawer
          context.goNamed(routeName);
        },
      );
    }

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header: Logo and Search Bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.network(
                        'https://new.dux-erp.com/assets/Img/duxlogo01.png',
                        height: 48,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'DUX',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Text(
                          isDark ? '🌞' : '🌙',
                          style: const TextStyle(fontSize: 24),
                        ),
                        tooltip: isDark ? 'Passer au thème clair' : 'Passer au thème sombre',
                        onPressed: () {
                          final nextTheme = isDark ? ThemeMode.light : ThemeMode.dark;
                          ref.read(themeControllerProvider.notifier).setThemeMode(nextTheme);
                        },
                      ),
                    ],
                  ),
                  AppSpacing.gapL,
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.close, size: 16),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              children: [
                buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  routeName: RouteNames.dashboard,
                  pathPrefix: '/dashboard',
                ),
                buildDrawerItem(
                  icon: Icons.history_outlined,
                  label: 'Journal d\'Activité',
                  routeName: RouteNames.activityFeed,
                  pathPrefix: '/activity-feed',
                ),
                buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  label: 'Commands',
                  routeName: RouteNames.commands,
                  pathPrefix: '/commands',
                ),
                buildDrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Préparations',
                  routeName: RouteNames.bonPreparationList,
                  pathPrefix: '/preparations',
                ),
                buildDrawerItem(
                  icon: Icons.storefront_outlined,
                  label: 'Station',
                  routeName: RouteNames.station,
                  pathPrefix: '/station',
                ),
                buildDrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  routeName: RouteNames.profile,
                  pathPrefix: '/profile',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Bottom Section: User Info and Logout
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      AppSpacing.gapM,
                      Expanded(
                        child: Text(
                          profileState.profile?.fullName ?? 'Utilisateur',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Se déconnecter',
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.m),
                  child: DuxFooter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
