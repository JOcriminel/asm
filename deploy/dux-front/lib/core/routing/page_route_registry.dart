import 'package:flutter/material.dart';
import 'package:dux_front/core/routing/route_constants.dart';

class PageRouteInfo {
  final String routeName;
  final String pathPrefix;
  final String pathToGo;
  final IconData icon;
  final Color defaultColor;

  const PageRouteInfo({
    required this.routeName,
    required this.pathPrefix,
    required this.pathToGo,
    required this.icon,
    required this.defaultColor,
  });
}

final Map<String, PageRouteInfo> pageRouteRegistry = {
  'HOME': const PageRouteInfo(
    routeName: RouteNames.dashboard,
    pathPrefix: '/dashboard',
    pathToGo: '/dashboard',
    icon: Icons.home_outlined,
    defaultColor: Colors.blue,
  ),
  'KPI_DASHBOARD': const PageRouteInfo(
    routeName: RouteNames.kpiDashboard,
    pathPrefix: '/kpi-dashboard',
    pathToGo: '/kpi-dashboard',
    icon: Icons.dashboard_outlined,
    defaultColor: Colors.teal,
  ),
  'CLIENTS': const PageRouteInfo(
    routeName: RouteNames.clients,
    pathPrefix: '/clients',
    pathToGo: '/clients',
    icon: Icons.group_outlined,
    defaultColor: Colors.purple,
  ),
  'ACTIVITY_FEED': const PageRouteInfo(
    routeName: RouteNames.activityFeed,
    pathPrefix: '/activity-feed',
    pathToGo: '/activity-feed',
    icon: Icons.history_outlined,
    defaultColor: Colors.amber,
  ),
  'BC': const PageRouteInfo(
    routeName: 'BC',
    pathPrefix: '/commands',
    pathToGo: '/commands',
    icon: Icons.receipt_long_rounded,
    defaultColor: Colors.blue,
  ),
  'BP': const PageRouteInfo(
    routeName: 'BP',
    pathPrefix: '/pages/bon-preparation',
    pathToGo: '/pages/bon-preparation/list',
    icon: Icons.inventory_2_outlined,
    defaultColor: Colors.green,
  ),
  'BPR': const PageRouteInfo(
    routeName: RouteNames.bonReservationList,
    pathPrefix: '/pages/bon-reservation',
    pathToGo: '/pages/bon-reservation/list',
    icon: Icons.assignment_turned_in_outlined,
    defaultColor: Colors.blue,
  ),
  'BS': const PageRouteInfo(
    routeName: 'BS',
    pathPrefix: '/pages/bon-sortie',
    pathToGo: '/pages/bon-sortie/list',
    icon: Icons.local_shipping_outlined,
    defaultColor: Colors.orange,
  ),
  'STATION': const PageRouteInfo(
    routeName: RouteNames.station,
    pathPrefix: '/station',
    pathToGo: '/station',
    icon: Icons.storefront_outlined,
    defaultColor: Colors.green,
  ),
  'PROFILE': const PageRouteInfo(
    routeName: RouteNames.profile,
    pathPrefix: '/profile',
    pathToGo: '/profile',
    icon: Icons.person_outline,
    defaultColor: Colors.pink,
  ),
  'ADMIN_DASHBOARD': const PageRouteInfo(
    routeName: 'dashboardAdmin',
    pathPrefix: '/dashboard-admin',
    pathToGo: '/dashboard-admin',
    icon: Icons.admin_panel_settings_outlined,
    defaultColor: Colors.indigo,
  ),
};
