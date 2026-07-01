import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_menu_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_menu_item.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/core/widgets/dux_notification_badge.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_popup_menu_design_provider.dart';

class TimetreeAccueilScreen extends ConsumerWidget {
  const TimetreeAccueilScreen({super.key});

  Color _parseColor(String hex, Color fallback) {
    try {
      final cleanHex = hex.toUpperCase().replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'settings':
        return Icons.settings_rounded;
      case 'apps':
        return Icons.apps_rounded;
      case 'menu':
        return Icons.menu_rounded;
      case 'more_vert':
      default:
        return Icons.more_vert_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timetreeMenuAsync = ref.watch(timetreeMenuProvider);
    final authState = ref.watch(authControllerProvider);
    final role = authState.user?.role.toUpperCase() ?? 'MEMBER';
    final isAdmin = role == 'ADMIN' || role == 'ADMINISTRATEUR';

    final design = ref.watch(timetreePopupMenuDesignProvider);
    final bgColor = _parseColor(design.backgroundColorHex, theme.colorScheme.surface);
    final iconColor = _parseColor(design.iconColorHex, theme.colorScheme.onSurface);
    final textColor = _parseColor(design.textColorHex, theme.colorScheme.onSurface);
    final menuIcon = _getIconData(design.iconName);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Calendrier – Accueil'),
        elevation: 0,
        actions: [
          const DuxNotificationBadge(),
          PopupMenuButton<String>(
            icon: Icon(menuIcon, color: iconColor),
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'categories') {
                context.push('/timetree/categories');
              } else if (val == 'pages') {
                context.push('/timetree/pages');
              } else if (val == 'dashboard') {
                context.push('/timetree/dashboard');
              } else if (val == 'customize') {
                _showCustomizeMenuDialog(context, ref, design);
              }
            },
            itemBuilder: (context) => [
              if (isAdmin) ...[
                if (design.showCategories)
                  PopupMenuItem(
                    value: 'categories',
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, color: textColor),
                        const SizedBox(width: 12),
                        Text('Gestion Catégories', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (design.showPages)
                  PopupMenuItem(
                    value: 'pages',
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file_outlined, color: textColor),
                        const SizedBox(width: 12),
                        Text('Gestion Pages', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (design.showDashboard)
                  PopupMenuItem(
                    value: 'dashboard',
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_outlined, color: textColor),
                        const SizedBox(width: 12),
                        Text('Tableau de Bord', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'customize',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, color: textColor),
                      const SizedBox(width: 12),
                      Text('Personnaliser le Menu', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(timetreeMenuProvider.future),
        child: timetreeMenuAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger l\'accueil du calendrier',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(timetreeMenuProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) {
            final user = authState.user;

            bool isItemAccessible(TimetreeMenuItem item) {
              if (user == null) return false;
              final userRole = user.role.toUpperCase();
              if (userRole == 'ADMIN' || userRole == 'ADMINISTRATEUR') {
                return true;
              }
              if (item.allowedRoles != null && item.allowedRoles!.trim().isNotEmpty) {
                final rolesList = item.allowedRoles!
                    .split(',')
                    .map((r) => r.trim().toUpperCase())
                    .where((r) => r.isNotEmpty);
                if (rolesList.isNotEmpty && !rolesList.contains(userRole)) {
                  return false;
                }
              }
              if (item.allowedUsers != null && item.allowedUsers!.trim().isNotEmpty) {
                final usersList = item.allowedUsers!
                    .split(',')
                    .map((u) => u.trim().toLowerCase())
                    .where((u) => u.isNotEmpty);
                if (usersList.isNotEmpty) {
                  final lowerUsername = user.username.toLowerCase();
                  final lowerEmail = user.email.toLowerCase();
                  if (!usersList.contains(lowerUsername) && !usersList.contains(lowerEmail)) {
                    return false;
                  }
                }
              }
              return true;
            }

            final filteredCategories = categories.where(isItemAccessible).map((cat) {
              final filteredPages = cat.children.where(isItemAccessible).toList();
              return TimetreeMenuItem(
                id: cat.id,
                title: cat.title,
                path: cat.path,
                displayOrder: cat.displayOrder,
                allowedRoles: cat.allowedRoles,
                allowedUsers: cat.allowedUsers,
                children: filteredPages,
              );
            }).where((cat) => cat.children.isNotEmpty).toList();

            if (filteredCategories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune page ou catégorie accessible',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return _CategoryCard(category: category);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category});

  final TimetreeMenuItem category;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  double _scale = 1.0;

  LinearGradient _getGradient(String title, ThemeData theme) {
    final clean = title.toLowerCase();
    if (clean.contains('admin') || clean.contains('paramètre')) {
      return LinearGradient(
        colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (clean.contains('calendrier') || clean.contains('planning')) {
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.indigo.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (clean.contains('analyse') || clean.contains('stat')) {
      return LinearGradient(
        colors: [Colors.teal.shade400, Colors.green.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Default fallback gradient using theme primary/secondary
    return LinearGradient(
      colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getCategoryIcon(String title) {
    final clean = title.toLowerCase();
    if (clean.contains('admin') || clean.contains('paramètre')) {
      return Icons.admin_panel_settings_rounded;
    } else if (clean.contains('calendrier') || clean.contains('planning')) {
      return Icons.calendar_month_rounded;
    } else if (clean.contains('analyse') || clean.contains('stat')) {
      return Icons.analytics_rounded;
    }
    return Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = _getGradient(widget.category.title, theme);
    final icon = _getCategoryIcon(widget.category.title);
    final pageCount = widget.category.children.length;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () => _showCategoryPages(context, widget.category),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background decoration
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pageCount == 1 ? '1 page' : '$pageCount pages',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPages(BuildContext context, TimetreeMenuItem category) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category.title),
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (category.children.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Aucune page disponible dans cette catégorie',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: category.children.length,
                    itemBuilder: (context, index) {
                      final page = category.children[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPageIcon(page.path),
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          page.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          context.go(page.path); // Navigate to page
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getPageIcon(String path) {
    final clean = path.toLowerCase();
    if (clean.contains('calendar-view')) {
      return Icons.calendar_month_rounded;
    } else if (clean.contains('search')) {
      return Icons.search_rounded;
    } else if (clean.contains('audit-logs')) {
      return Icons.history_rounded;
    } else if (clean.contains('roles-permissions')) {
      return Icons.security_rounded;
    } else if (clean.contains('custom-fields')) {
      return Icons.settings_applications_rounded;
    } else if (clean.contains('traceability')) {
      return Icons.track_changes_rounded;
    }
    return Icons.insert_drive_file_outlined;
  }
}

void _showCustomizeMenuDialog(BuildContext context, WidgetRef ref, TimetreePopupMenuDesign current) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      
      String selectedIcon = current.iconName;
      String bgHex = current.backgroundColorHex;
      String iconHex = current.iconColorHex;
      String textHex = current.textColorHex;
      bool showCats = current.showCategories;
      bool showPages = current.showPages;
      bool showDash = current.showDashboard;

      final formKey = GlobalKey<FormState>();

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.palette_outlined, color: Colors.blueAccent),
                SizedBox(width: 12),
                Text('Design du Menu Pop-up'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choisissez un thème prédéfini :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Clair Moderne'),
                          onPressed: () {
                            setState(() {
                              bgHex = '#FFFFFF';
                              iconHex = '#1A73E8';
                              textHex = '#202124';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Sombre Élégant'),
                          onPressed: () {
                            setState(() {
                              bgHex = '#1E1E2E';
                              iconHex = '#F1F3F4';
                              textHex = '#F1F3F4';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Royal Indigo'),
                          onPressed: () {
                            setState(() {
                              bgHex = '#1A237E';
                              iconHex = '#FFD700';
                              textHex = '#FFFFFF';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Forêt Teal'),
                          onPressed: () {
                            setState(() {
                              bgHex = '#E0F2F1';
                              iconHex = '#004D40';
                              textHex = '#004D40';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Configuration Personnalisée :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Icon selection dropdown
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icône du menu',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'more_vert', child: Row(children: [Icon(Icons.more_vert_rounded), SizedBox(width: 8), Text('Points Verticaux')])),
                        DropdownMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_rounded), SizedBox(width: 8), Text('Engrenage Settings')])),
                        DropdownMenuItem(value: 'apps', child: Row(children: [Icon(Icons.apps_rounded), SizedBox(width: 8), Text('Applications (Mosaïque)')])),
                        DropdownMenuItem(value: 'menu', child: Row(children: [Icon(Icons.menu_rounded), SizedBox(width: 8), Text('Menu Hamburger')])),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedIcon = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Background color hex field
                    TextFormField(
                      initialValue: bgHex,
                      key: ValueKey('bg-$bgHex'),
                      decoration: const InputDecoration(
                        labelText: 'Couleur de fond (HEX)',
                        hintText: '#FFFFFF',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(val)) {
                          return 'Format invalide (ex: #FFFFFF)';
                        }
                        return null;
                      },
                      onChanged: (val) => bgHex = val,
                    ),
                    const SizedBox(height: 12),

                    // Icon color hex field
                    TextFormField(
                      initialValue: iconHex,
                      key: ValueKey('icon-$iconHex'),
                      decoration: const InputDecoration(
                        labelText: 'Couleur de l\'icône du menu (HEX)',
                        hintText: '#000000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(val)) {
                          return 'Format invalide (ex: #000000)';
                        }
                        return null;
                      },
                      onChanged: (val) => iconHex = val,
                    ),
                    const SizedBox(height: 12),

                    // Text color hex field
                    TextFormField(
                      initialValue: textHex,
                      key: ValueKey('text-$textHex'),
                      decoration: const InputDecoration(
                        labelText: 'Couleur du texte des options (HEX)',
                        hintText: '#000000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(val)) {
                          return 'Format invalide (ex: #000000)';
                        }
                        return null;
                      },
                      onChanged: (val) => textHex = val,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Visibilité des options :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Gestion Catégories'),
                      value: showCats,
                      onChanged: (val) => setState(() => showCats = val),
                    ),
                    SwitchListTile(
                      title: const Text('Gestion Pages'),
                      value: showPages,
                      onChanged: (val) => setState(() => showPages = val),
                    ),
                    SwitchListTile(
                      title: const Text('Tableau de Bord'),
                      value: showDash,
                      onChanged: (val) => setState(() => showDash = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newDesign = TimetreePopupMenuDesign(
                      backgroundColorHex: bgHex,
                      iconColorHex: iconHex,
                      textColorHex: textHex,
                      iconName: selectedIcon,
                      showCategories: showCats,
                      showPages: showPages,
                      showDashboard: showDash,
                    );
                    await ref.read(timetreePopupMenuDesignProvider.notifier).updateDesign(newDesign);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Design du menu mis à jour avec succès')),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );
}
