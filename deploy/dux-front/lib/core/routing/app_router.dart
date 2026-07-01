import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/task_type.dart';
import 'route_constants.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/workspace_selector_screen.dart';
import '../../features/auth/presentation/screens/intro_walkthrough_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/kpi_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/activity_feed_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/commands/presentation/screens/commands_list_screen.dart';
import '../../features/command_details/presentation/screens/command_details_screen.dart';
import '../../features/station/presentation/screens/station_details_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/accueil_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/categories_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/pages_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/dashboard_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/roles_permissions_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_calendar_view_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/custom_fields_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_audit_logs_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_event_traceability_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_search_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/clients/presentation/screens/client_list_screen.dart';
import '../../features/clients/presentation/screens/client_details_screen.dart';
import '../../features/bon_preparation/presentation/screens/bon_preparation_list_screen.dart';
import '../../features/bon_preparation/presentation/screens/bon_preparation_detail_screen.dart';
import '../../features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import '../../features/bon_preparation/presentation/screens/preparation_checklist_screen.dart';
import '../../features/bon_preparation/presentation/screens/article_checklist_screen.dart';
import '../../features/bon_preparation/domain/models/bon_preparation.dart';
import '../../features/checklist/presentation/screens/checklist_admin_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_admin_screen.dart';
import '../../features/dashboard/presentation/screens/dynamic_screens_config_screen.dart';
import '../../features/dashboard/presentation/screens/edit_screen_config_screen.dart';
import '../../features/dashboard/presentation/screens/categories_admin_screen.dart';
import '../../features/dashboard/presentation/screens/dynamic_document_list_screen.dart';
import '../../features/dashboard/presentation/screens/gestion_vente_screen.dart';
import '../../features/checklist/presentation/screens/groups_admin_screen.dart';
import '../../features/checklist/presentation/screens/task_types_admin_screen.dart';
import '../../features/checklist/presentation/screens/tasks_admin_screen.dart';
import '../../features/checklist/presentation/screens/articles_admin_screen.dart';
import '../../features/bon_sortie/presentation/screens/bon_sortie_list_screen.dart';
import '../../features/bon_sortie/presentation/screens/bon_sortie_detail_screen.dart';
import 'package:dux_front/features/notifications/presentation/screens/notification_history_screen.dart';
import 'package:dux_front/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:dux_front/features/notifications/presentation/screens/admin_announcement_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      debugPrint('Router Global Redirect: matchedLocation = ${state.matchedLocation}, uri = ${state.uri}');
      final loginLoc = RoutePaths.login;
      final splashLoc = RoutePaths.splash;

      final isLoggedIn = authState.isAuthenticated;
      final isChecking = authState.isChecking;

      final isGoingToLogin = state.matchedLocation == loginLoc;
      final isGoingToSplash = state.matchedLocation == splashLoc;

      if (isChecking) {
        return isGoingToSplash ? null : splashLoc;
      }

      if (!isLoggedIn) {
        // If not logged in and not going to login, redirect to login
        if (!isGoingToLogin) return loginLoc;
        return null;
      }

      // If logged in
      if (isGoingToLogin || isGoingToSplash) {
        return RoutePaths.workspaceSelector;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.workspaceSelector,
        name: RouteNames.workspaceSelector,
        builder: (context, state) => const WorkspaceSelectorScreen(),
      ),
      GoRoute(
        path: '/intro-walkthrough',
        name: 'introWalkthrough',
        builder: (context, state) => const IntroWalkthroughScreen(),
      ),
      
      // Detail and full-screen routes configured on the root navigator (sibling to Shells)
      GoRoute(
        path: '/clients/details/:id',
        name: RouteNames.clientDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ClientDetailsScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/commands/details/:id',
        name: RouteNames.commandDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CommandDetailsScreen(commandId: id);
        },
      ),
      
      // Bon de Préparation details
      GoRoute(
        path: '/pages/bon-preparation/detail/:id',
        name: RouteNames.bonPreparationDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final docTypeParam = state.uri.queryParameters['type'];
          final task = TaskTypeExtension.fromKey(docTypeParam);
          final docType = task?.key ?? 'BP';
          debugPrint('Router: Building detail page with id: $id, type: $docType');
          return BonPreparationDetailScreen(preparationId: id, docType: docType);
        },
      ),
      GoRoute(
        path: '/pages/bon-preparation/serial-number',
        name: RouteNames.bonPreparationSerialNumber,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as SerialNumberArgs;
          return SerialNumberEntryScreen(args: args);
        },
      ),
      GoRoute(
        path: '/pages/bon-preparation/checklist',
        name: RouteNames.bonPreparationChecklist,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return PreparationChecklistScreen(
            preparationId: args['preparationId'] as String,
            docType: args['docType'] as String? ?? 'BP',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bonPreparationArticleChecklist,
        name: RouteNames.bonPreparationArticleChecklist,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ArticleChecklistScreen(
            preparationId: args['preparationId'] as String,
            article: args['article'] as PreparationArticle,
            docType: args['docType'] as String? ?? 'BP',
          );
        },
      ),

      // Bon de Sortie details
      GoRoute(
        path: '/pages/bon-sortie/detail/:id',
        name: RouteNames.bonSortieDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BonSortieDetailScreen(sortieId: id);
        },
      ),

      // Bon de Réservation details
      GoRoute(
        path: '/pages/bon-reservation/detail/:id',
        name: RouteNames.bonReservationDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BonPreparationDetailScreen(preparationId: id, docType: 'BPR');
        },
      ),
      GoRoute(
        path: '/pages/bon-reservation/serial-number',
        name: RouteNames.bonReservationSerialNumber,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as SerialNumberArgs;
          return SerialNumberEntryScreen(args: args);
        },
      ),
      GoRoute(
        path: '/pages/bon-reservation/checklist',
        name: RouteNames.bonReservationChecklist,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return PreparationChecklistScreen(
            preparationId: args['preparationId'] as String,
            docType: args['docType'] as String? ?? 'BPR',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bonReservationArticleChecklist,
        name: RouteNames.bonReservationArticleChecklist,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ArticleChecklistScreen(
            preparationId: args['preparationId'] as String,
            article: args['article'] as PreparationArticle,
            docType: args['docType'] as String? ?? 'BPR',
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: RoutePaths.kpiDashboard,
                name: RouteNames.kpiDashboard,
                builder: (context, state) => const KpiDashboardScreen(),
              ),
              GoRoute(
                path: '/activity-feed',
                name: RouteNames.activityFeed,
                builder: (context, state) => const ActivityFeedScreen(),
              ),
              GoRoute(
                path: RoutePaths.clients,
                name: RouteNames.clients,
                builder: (context, state) => const ClientsListScreen(),
              ),
              GoRoute(
                path: '/dashboard-admin',
                name: 'dashboardAdmin',
                builder: (context, state) => const DashboardAdminScreen(),
              ),
              GoRoute(
                path: '/checklist-admin',
                name: 'checklistAdmin',
                builder: (context, state) => const ChecklistAdminScreen(),
                routes: [
                  GoRoute(
                    path: 'groups',
                    builder: (context, state) => const GroupsAdminScreen(),
                  ),
                  GoRoute(
                    path: 'types',
                    builder: (context, state) => const TaskTypesAdminScreen(),
                  ),
                  GoRoute(
                    path: 'tasks',
                    builder: (context, state) => const TasksAdminScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/articles-admin',
                name: 'articlesAdmin',
                builder: (context, state) => const ArticlesAdminScreen(),
              ),
              GoRoute(
                path: '/admin/screen-settings',
                name: 'dynamicScreenSettings',
                builder: (context, state) => const DynamicScreensConfigScreen(),
                routes: [
                  GoRoute(
                    path: 'edit/:type',
                    name: 'editScreenSettings',
                    builder: (context, state) {
                      final type = state.pathParameters['type'] ?? '';
                      return EditScreenConfigScreen(docType: type);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/admin/categories',
                name: 'categoriesAdmin',
                builder: (context, state) => const CategoriesAdminScreen(),
              ),
              GoRoute(
                path: '/pages/dynamic-list/:type',
                name: 'dynamicDocumentList',
                builder: (context, state) {
                  final type = state.pathParameters['type'] ?? '';
                  return DynamicDocumentListScreen(docType: type);
                },
              ),
              GoRoute(
                path: '/pages/bon-reservation/list',
                name: RouteNames.bonReservationList,
                builder: (context, state) => const DynamicDocumentListScreen(docType: 'BPR'),
              ),
              GoRoute(
                path: RoutePaths.gestionVente,
                name: RouteNames.gestionVente,
                builder: (context, state) => const GestionVenteScreen(),
              ),
              GoRoute(
                path: '/pages/category/:name',
                name: 'categoryScreen',
                builder: (context, state) {
                  final name = state.pathParameters['name'] ?? '';
                  return GestionVenteScreen(categoryName: name);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.commands,
                name: RouteNames.commands,
                builder: (context, state) => const CommandsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pages/bon-preparation',
                redirect: (context, state) {
                  debugPrint('Router BonPrep Redirect: matchedLocation = ${state.matchedLocation}, uri = ${state.uri}');
                  final path = state.uri.path;
                  if (path == '/pages/bon-preparation' || path == '/pages/bon-preparation/') {
                    return '/pages/bon-preparation/list';
                  }
                  return null;
                },
                builder: (context, state) => const SizedBox.shrink(),
                routes: [
                  GoRoute(
                    path: 'list',
                    name: RouteNames.bonPreparationList,
                    builder: (context, state) => const BonPreparationListScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pages/bon-sortie',
                redirect: (context, state) {
                  final path = state.uri.path;
                  if (path == '/pages/bon-sortie' || path == '/pages/bon-sortie/') {
                    return '/pages/bon-sortie/list';
                  }
                  return null;
                },
                builder: (context, state) => const SizedBox.shrink(),
                routes: [
                  GoRoute(
                    path: 'list',
                    name: RouteNames.bonSortieList,
                    builder: (context, state) => const BonSortieListScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.station,
                name: RouteNames.station,
                builder: (context, state) => const StationDetailsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    // TimeTree routes
    GoRoute(
      path: '/timetree',
      redirect: (context, state) => '/timetree/accueil',
    ),
    GoRoute(
      path: '/timetree/accueil',
      name: 'timetreeAccueil',
      builder: (context, state) => TimetreeAccueilScreen(),
    ),
    GoRoute(
      path: '/timetree/categories',
      name: 'timetreeCategories',
      builder: (context, state) => TimetreeCategoriesScreen(),
    ),
    GoRoute(
      path: '/timetree/pages',
      name: 'timetreePages',
      builder: (context, state) => TimetreePagesScreen(),
    ),
    GoRoute(
      path: '/timetree/groups',
      redirect: (context, state) => '/timetree/calendar-view',
    ),
    GoRoute(
      path: '/timetree/roles-permissions',
      name: 'timetreeRolesPermissions',
      builder: (context, state) => const TimetreeRolesPermissionsScreen(),
    ),
    GoRoute(
      path: '/timetree/dashboard',
      name: 'timetreeDashboard',
      builder: (context, state) => const TimetreeDashboardScreen(),
    ),
    GoRoute(
      path: '/timetree/membership-calendars',
      redirect: (context, state) => '/timetree/calendar-view',
    ),
    GoRoute(
      path: '/timetree/calendar-view',
      name: 'timetreeCalendarView',
      builder: (context, state) => const TimetreeCalendarViewScreen(),
    ),
    GoRoute(
      path: '/timetree/custom-fields',
      name: 'timetreeCustomFields',
      builder: (context, state) => const TimetreeCustomFieldsScreen(),
    ),
    GoRoute(
      path: '/timetree/admin/audit-logs',
      name: 'timetreeAuditLogs',
      builder: (context, state) => const TimetreeAuditLogsScreen(),
    ),
    GoRoute(
      path: '/timetree/traceability',
      name: 'timetreeTraceability',
      builder: (context, state) => const TimetreeEventTraceabilityScreen(),
    ),
    GoRoute(
      path: '/timetree/profile',
      name: 'timetreeProfile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/timetree/search',
      name: 'timetreeSearch',
      builder: (context, state) => const TimetreeSearchScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notificationsHistory',
      builder: (context, state) => const NotificationHistoryScreen(),
    ),
    GoRoute(
      path: '/notifications/settings',
      name: 'notificationSettings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/timetree/admin/announcements',
      name: 'adminAnnouncements',
      builder: (context, state) => const AdminAnnouncementScreen(),
    ),
    ],
  );
});
