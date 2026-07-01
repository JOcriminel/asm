import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/routing/page_route_registry.dart';
import 'package:dux_front/core/widgets/dux_notification_badge.dart';
import 'package:dux_front/core/widgets/dux_tutorial_helper.dart';
import 'package:dux_front/core/services/tutorial_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey _menuCardKey = GlobalKey();
  final GlobalKey _appBarHomeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final hasSeen = await tutorialService.hasSeenDashboardTour();
    if (!hasSeen && mounted) {
      _showDashboardTutorial();
    }
  }

  void _showDashboardTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "appBarHomeKey",
        keyTarget: _appBarHomeKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return DuxTutorialHelper.buildTooltipContent(
                context: context,
                title: "Raccourci Accueil",
                description: "Appuyez sur cette icône pour revenir instantanément à l'écran d'accueil depuis n'importe quel sous-menu.",
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "menuCardKey",
        keyTarget: _menuCardKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return DuxTutorialHelper.buildTooltipContent(
                context: context,
                title: "Modules DUX",
                description: "Voici vos modules opérationnels. Cliquez sur n'importe quelle carte pour commencer une action (KPI, Clients, ou Bons de Préparation).",
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
                isLastStep: true,
              );
            },
          ),
        ],
      ),
    ];

    DuxTutorialHelper.showTutorial(
      context: context,
      targets: targets,
      onFinish: () {
        ref.read(tutorialServiceProvider).setSeenDashboardTour(true);
      },
      onSkip: () {
        ref.read(tutorialServiceProvider).setSeenDashboardTour(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);

    if (configState.isLoading) {
      return const DuxLoadingScreen(isFullScreen: true);
    }

    final configs = configState.configs;
    final List<Map<String, dynamic>> menuItems = [];

    // 1. Add active categories as home cards dynamically
    for (final category in configState.categories) {
      if (category.active) {
        IconData icon = Icons.folder_open_outlined;
        Color color = Colors.blueGrey;
        
        if (category.name == 'Gestion de Vente') {
          icon = Icons.shopping_bag_outlined;
          color = Colors.blue;
        }
        
        menuItems.add({
          'title': category.name.replaceAll(' ', '\n'),
          'icon': icon,
          'route': '/pages/category/${category.name}',
          'color': color,
        });
      }
    }

    // 2. Add active pages directly belonging to Accueil
    configs.forEach((key, config) {
      if (key == 'HOME' || key == 'BC' || key == 'BP' || key == 'BS') return;
      if (!config.isActive) return;

      final isCatInactive = config.category != null &&
          config.category!.isNotEmpty &&
          configState.categories.any((c) => c.name == config.category && !c.active);

      final isAccueil = config.category == null ||
          config.category!.isEmpty ||
          config.category == 'Accueil' ||
          isCatInactive;

      if (!isAccueil) return; // Belongs to an active category, shown inside category details

      final reg = pageRouteRegistry[key];
      if (reg != null) {
        final title = config.pageTitle.isNotEmpty ? config.pageTitle : reg.routeName;
        menuItems.add({
          'title': title.replaceAll(' ', '\n'),
          'icon': reg.icon,
          'route': reg.pathToGo,
          'color': reg.defaultColor,
        });
      } else {
        // Custom dynamic pages without category
        Color primaryColor = Colors.blue;
        try {
          final cleaned = config.primaryColor.replaceAll('#', '');
          primaryColor = Color(int.parse('FF$cleaned', radix: 16));
        } catch (_) {}

        menuItems.add({
          'title': config.pageTitle.replaceAll(' ', '\n'),
          'icon': Icons.assignment_rounded,
          'route': '/pages/dynamic-list/$key',
          'color': primaryColor,
        });
      }
    });

    // 3. Sort menuItems to keep a predictable layout order
    final predefinedHomeOrder = [
      '/kpi-dashboard',
      '/pages/category/Gestion de Vente',
      '/clients',
      '/activity-feed',
      '/station',
      '/profile',
      '/dashboard-admin'
    ];

    menuItems.sort((a, b) {
      final routeA = a['route'] as String;
      final routeB = b['route'] as String;

      final indexA = predefinedHomeOrder.indexOf(routeA);
      final indexB = predefinedHomeOrder.indexOf(routeB);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1;
      } else if (indexB != -1) {
        return 1;
      } else {
        return routeA.compareTo(routeB);
      }
    });

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('DUX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          const DuxNotificationBadge(),
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
                key: _appBarHomeKey,
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
          childAspectRatio: 0.82,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final card = _MenuCard(
            title: item['title'] as String,
            icon: item['icon'] as IconData,
            color: item['color'] as Color,
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

          if (index == 0) {
            return KeyedSubtree(
              key: _menuCardKey,
              child: card,
            );
          }
          return card;
        },
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
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
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.color,
                ),
              ),
              AppSpacing.gapM,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
