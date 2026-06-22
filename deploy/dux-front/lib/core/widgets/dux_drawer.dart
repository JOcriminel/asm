import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_footer.dart';
import 'package:dux_front/core/theme/theme_controller.dart';
import 'package:dux_front/features/profile/presentation/controllers/profile_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:dux_front/core/routing/page_route_registry.dart';

class DuxDrawer extends ConsumerWidget {
  const DuxDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final themeMode = ref.watch(themeControllerProvider);
    final configState = ref.watch(screenConfigControllerProvider);
    
    if (configState.isLoading) {
      return Drawer(
        backgroundColor: theme.colorScheme.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final configs = configState.configs;
    
    final activePages = configs.entries.where((entry) => entry.value.isActive).toList();
    final Map<String, List<MapEntry<String, ScreenConfig>>> pagesByCategory = {};
    for (final cat in configState.categories) {
      if (cat.active) {
        pagesByCategory[cat.name] = [];
      }
    }
    
    final List<MapEntry<String, ScreenConfig>> mainPages = [];

    for (final entry in activePages) {
      final cat = entry.value.category;
      if (cat != null && cat.isNotEmpty && pagesByCategory.containsKey(cat)) {
        pagesByCategory[cat]!.add(entry);
      } else {
        mainPages.add(entry);
      }
    }

    // Dynamic categorizations split
    final topKeys = ['HOME', 'KPI_DASHBOARD', 'CLIENTS', 'ACTIVITY_FEED'];
    final bottomKeys = ['STATION', 'PROFILE', 'ADMIN_DASHBOARD'];

    final topPages = mainPages.where((entry) => topKeys.contains(entry.key)).toList();
    final bottomPages = mainPages.where((entry) => bottomKeys.contains(entry.key)).toList();
    final customMainPages = mainPages.where((entry) => !topKeys.contains(entry.key) && !bottomKeys.contains(entry.key)).toList();

    // Sort sections for stable layout order
    topPages.sort((a, b) => topKeys.indexOf(a.key).compareTo(topKeys.indexOf(b.key)));
    bottomPages.sort((a, b) => bottomKeys.indexOf(a.key).compareTo(bottomKeys.indexOf(b.key)));
    customMainPages.sort((a, b) => a.value.pageTitle.compareTo(b.value.pageTitle));

    IconData getCategoryIcon(String categoryName) {
      if (categoryName == 'Gestion de Vente') {
        return Icons.shopping_bag_outlined;
      }
      return Icons.folder_open_outlined;
    }
    
    // Determine if we are currently in dark mode
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    Widget buildMainDrawerItem(MapEntry<String, ScreenConfig> entry) {
      final reg = pageRouteRegistry[entry.key];
      final pathPrefix = reg?.pathPrefix ?? '/pages/dynamic-list/${entry.key}';
      final pathToGo = reg?.pathToGo ?? '/pages/dynamic-list/${entry.key}';
      final icon = reg?.icon ?? Icons.assignment_rounded;

      final isSelected = currentRoute.startsWith(pathPrefix);

      Color itemColor = theme.colorScheme.primary;
      try {
        final cleanHex = entry.value.primaryColor.replaceAll('#', '');
        itemColor = Color(int.parse('FF$cleanHex', radix: 16));
      } catch (_) {}

      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? itemColor : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          entry.value.pageTitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? itemColor : theme.colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        selectedTileColor: itemColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        onTap: () {
          Navigator.pop(context); // Close drawer
          context.go(pathToGo);
        },
      );
    }

    Widget buildCategoryTile(String categoryName, List<MapEntry<String, ScreenConfig>> pages) {
      final isAnyChildSelected = pages.any((entry) {
        final reg = pageRouteRegistry[entry.key];
        final pathPrefix = reg?.pathPrefix ?? '/pages/dynamic-list/${entry.key}';
        return currentRoute.startsWith(pathPrefix);
      });

      return ExpansionTile(
        leading: Icon(
          getCategoryIcon(categoryName),
          color: isAnyChildSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          categoryName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isAnyChildSelected ? FontWeight.bold : FontWeight.normal,
            color: isAnyChildSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        childrenPadding: const EdgeInsets.only(left: AppSpacing.l),
        shape: const Border(), // remove default divider lines
        collapsedShape: const Border(),
        children: pages.map((entry) {
          final reg = pageRouteRegistry[entry.key];
          final pathPrefix = reg?.pathPrefix ?? '/pages/dynamic-list/${entry.key}';
          final pathToGo = reg?.pathToGo ?? '/pages/dynamic-list/${entry.key}';
          final icon = reg?.icon ?? Icons.assignment_rounded;

          final isSelected = currentRoute.startsWith(pathPrefix);
              
          Color itemColor = theme.colorScheme.primary;
          try {
            final cleanHex = entry.value.primaryColor.replaceAll('#', '');
            itemColor = Color(int.parse('FF$cleanHex', radix: 16));
          } catch (_) {}

          return ListTile(
            dense: true,
            leading: Icon(
              icon,
              color: isSelected ? itemColor : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            title: Text(
              entry.value.pageTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? itemColor : theme.colorScheme.onSurface,
              ),
            ),
            selected: isSelected,
            selectedTileColor: itemColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.go(pathToGo);
            },
          );
        }).toList(),
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
                // 1. Top main pages (Home, KPI, Clients, Activity Feed)
                ...topPages.map((entry) => buildMainDrawerItem(entry)),
                
                // 2. Categories dropdowns
                ...pagesByCategory.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .map((entry) => buildCategoryTile(entry.key, entry.value)),

                // 3. Custom dynamic pages directly on Accueil
                ...customMainPages.map((entry) => buildMainDrawerItem(entry)),

                // 4. Bottom main pages (Station, Profile, Admin Dashboard)
                ...bottomPages.map((entry) => buildMainDrawerItem(entry)),
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
