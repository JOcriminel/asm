import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_constants.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/kpi_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/activity_feed_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/commands/presentation/screens/commands_list_screen.dart';
import '../../features/command_details/presentation/screens/command_details_screen.dart';
import '../../features/station/presentation/screens/station_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/clients/presentation/screens/client_list_screen.dart';
import '../../features/clients/presentation/screens/client_details_screen.dart';
import '../../features/bon_preparation/presentation/screens/bon_preparation_list_screen.dart';
import '../../features/bon_preparation/presentation/screens/bon_preparation_detail_screen.dart';
import '../../features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import '../../features/bon_preparation/presentation/screens/preparation_checklist_screen.dart';

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
      final dashboardLoc = RoutePaths.dashboard;

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
        return dashboardLoc;
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
                routes: [
                  GoRoute(
                    path: RoutePaths.clientDetails,
                    name: RouteNames.clientDetails,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ClientDetailsScreen(clientId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.commands,
                name: RouteNames.commands,
                builder: (context, state) => const CommandsListScreen(),
                routes: [
                  GoRoute(
                    path: RoutePaths.commandDetails,
                    name: RouteNames.commandDetails,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return CommandDetailsScreen(commandId: id);
                    },
                  ),
                ],
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
                  GoRoute(
                    path: 'detail/:id',
                    name: RouteNames.bonPreparationDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      debugPrint('Router: Building detail page with id: $id');
                      return BonPreparationDetailScreen(preparationId: id);
                    },
                  ),
                  GoRoute(
                    path: 'serial-number',
                    name: RouteNames.bonPreparationSerialNumber,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final args = state.extra as SerialNumberArgs;
                      return SerialNumberEntryScreen(args: args);
                    },
                  ),
                  GoRoute(
                    path: 'checklist',
                    name: RouteNames.bonPreparationChecklist,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return PreparationChecklistScreen(
                        preparationId: args['preparationId'] as String,
                      );
                    },
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
    ],
  );
});
