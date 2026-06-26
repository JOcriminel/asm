import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_footer.dart';
import 'package:dux_front/core/theme/theme_controller.dart';
import 'package:dux_front/features/profile/presentation/controllers/profile_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_menu_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_menu_item.dart';
import 'package:dux_front/core/models/screen_config.dart';

import 'package:dux_front/core/routing/page_route_registry.dart';
// screenConfigControllerProvider is still used for all non-TimeTree navigation.
import 'package:dux_front/core/services/screen_config_controller.dart';

class DuxDrawer extends ConsumerWidget {
  const DuxDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final themeMode = ref.watch(themeControllerProvider);
    final configState = ref.watch(screenConfigControllerProvider);
    // Timetree dynamic menu handling
    final timetreeMenuAsync = ref.watch(timetreeMenuProvider);
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toUpperCase() ?? 'MEMBER';
    final membersAsync = ref.watch(timetreeMembersProvider);
    final currentUsername = authState.user?.username;
    final currentMember = currentUsername == null
        ? null
        : membersAsync.when(
            data: (list) => list.firstWhere(
              (m) => m.username.toLowerCase() == currentUsername.toLowerCase(),
              orElse: () => const TimetreeMember(id: '', username: '', fullName: '', email: '', role: ''),
            ),
            loading: () => null,
            error: (_, __) => null,
          );
    if (currentRoute.startsWith('/timetree')) {
      return timetreeMenuAsync.when(
        data: (menuItems) => _TimetreeDrawer(
          menuItems: menuItems,
          currentRoute: currentRoute,
          theme: theme,
          userRole: userRole,
        ),
        loading: () => const Drawer(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Drawer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Erreur de chargement du menu',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    onPressed: () => ref.invalidate(timetreeMenuProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
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
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.account_tree_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Espace Dux Calender',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/dashboard');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.grid_view_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Changer d\'espace',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/workspace-selector');
                  },
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
                        backgroundImage: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                            ? MemoryImage(base64Decode(currentMember.profilePicture!))
                            : null,
                        child: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                            ? null
                            : const Icon(Icons.person, color: Colors.grey),
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

// ---------------------------------------------------------------------------
// Private widget: Timetree-specific drawer
// ---------------------------------------------------------------------------

/// Renders the navigation drawer when the user is on a `/timetree` route.
///
/// Data comes from [timetreeMenuProvider] which uses the shared [dioProvider]
/// (auth-intercepted, base-URL configured). No local Dio() instance is created.
class _TimetreeDrawer extends ConsumerWidget {
  const _TimetreeDrawer({
    required this.menuItems,
    required this.currentRoute,
    required this.theme,
    required this.userRole,
  });

  final List<TimetreeMenuItem> menuItems;
  final String currentRoute;
  final ThemeData theme;
  final String userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final membersAsync = ref.watch(timetreeMembersProvider);
    final currentUsername = ref.watch(authControllerProvider).user?.username;
    final currentMember = currentUsername == null
        ? null
        : membersAsync.when(
            data: (list) => list.firstWhere(
              (m) => m.username.toLowerCase() == currentUsername.toLowerCase(),
              orElse: () => const TimetreeMember(id: '', username: '', fullName: '', email: '', role: ''),
            ),
            loading: () => null,
            error: (_, __) => null,
          );

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.m,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dux Calender',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Menu items ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.s,
              ),
              children: [
                ListTile(
                  leading: Icon(
                    Icons.dashboard_outlined,
                    color: currentRoute == '/timetree/dashboard'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Tableau de bord',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/dashboard'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/dashboard'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/dashboard',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/dashboard');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_month_outlined,
                    color: currentRoute == '/timetree/calendar-view'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Calendrier Combiné',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/calendar-view'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/calendar-view'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/calendar-view',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/calendar-view');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.search_outlined,
                    color: currentRoute == '/timetree/search'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Recherche Globale',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/search'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/search'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/search',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/search');
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                  child: Text(
                    'Administration',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.category_outlined,
                    color: currentRoute == '/timetree/categories'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Catégories',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/categories'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/categories'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/categories',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/categories');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.insert_drive_file_outlined,
                    color: currentRoute == '/timetree/pages'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Pages',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/pages'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/pages'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/pages',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/pages');
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.security_outlined,
                    color: currentRoute == '/timetree/roles-permissions'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Rôles & Permissions',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/roles-permissions'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/roles-permissions'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/roles-permissions',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/roles-permissions');
                  },
                ),

                if (userRole == 'ADMIN' || userRole == 'CHEF')
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: currentRoute == '/timetree/custom-fields'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Champs Personnalisés',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: currentRoute == '/timetree/custom-fields'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentRoute == '/timetree/custom-fields'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/timetree/custom-fields',
                    selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/timetree/custom-fields');
                    },
                  ),
                if (userRole == 'ADMIN' || userRole == 'ADMINISTRATEUR')
                  ListTile(
                    leading: Icon(
                      Icons.history_outlined,
                      color: currentRoute == '/timetree/admin/audit-logs'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Logs d\'audit',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: currentRoute == '/timetree/admin/audit-logs'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentRoute == '/timetree/admin/audit-logs'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/timetree/admin/audit-logs',
                    selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/timetree/admin/audit-logs');
                    },
                  ),
                if (userRole == 'ADMIN' || userRole == 'ADMINISTRATEUR' || userRole == 'CHEF')
                  ListTile(
                    leading: Icon(
                      Icons.track_changes_outlined,
                      color: currentRoute == '/timetree/traceability'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Traçabilité',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: currentRoute == '/timetree/traceability'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentRoute == '/timetree/traceability'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/timetree/traceability',
                    selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/timetree/traceability');
                    },
                  ),
                const Divider(),
                ...menuItems.map((item) => _buildItem(context, item)),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.person_rounded,
                    color: currentRoute == '/timetree/profile'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Mon profil',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: currentRoute == '/timetree/profile'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentRoute == '/timetree/profile'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: currentRoute == '/timetree/profile',
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/timetree/profile');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.phone_android_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Espace DUX Mobile',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/dashboard');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.grid_view_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Changer d\'espace',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/workspace-selector');
                  },
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
                        backgroundImage: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                            ? MemoryImage(base64Decode(currentMember.profilePicture!))
                            : null,
                        child: currentMember?.profilePicture != null && currentMember!.profilePicture!.isNotEmpty
                            ? null
                            : const Icon(Icons.person, color: Colors.grey),
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

  Widget _buildItem(BuildContext context, TimetreeMenuItem item) {
    final isSelected = currentRoute.startsWith(item.path);

    if (item.children.isNotEmpty) {
      // Render as expandable tile with children
      final isAnyChildSelected =
          item.children.any((c) => currentRoute.startsWith(c.path));
      return ExpansionTile(
        leading: Icon(
          Icons.folder_outlined,
          color: isAnyChildSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          item.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight:
                isAnyChildSelected ? FontWeight.bold : FontWeight.normal,
            color: isAnyChildSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        childrenPadding: const EdgeInsets.only(left: AppSpacing.l),
        shape: const Border(),
        collapsedShape: const Border(),
        children: item.children
            .map((child) => _buildItem(context, child))
            .toList(),
      );
    }

    return ListTile(
      leading: Icon(
        Icons.insert_drive_file_outlined,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      onTap: () {
        Navigator.pop(context);
        context.go(item.path);
      },
    );
  }
}
