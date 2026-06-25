import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/theme/theme_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/profile/presentation/controllers/profile_controller.dart';

class WorkspaceSelectorScreen extends ConsumerWidget {
  const WorkspaceSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 750;

    final fullName = profileState.profile?.fullName ?? 'Utilisateur';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                  ]
                : [
                    theme.colorScheme.surfaceContainerLowest,
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header Bar (Theme Switch & Logout) ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.m,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Theme toggler
                    IconButton(
                      icon: Text(
                        isDark ? '🌞' : '🌙',
                        style: const TextStyle(fontSize: 24),
                      ),
                      tooltip: isDark
                          ? 'Passer au thème clair'
                          : 'Passer au thème sombre',
                      onPressed: () {
                        final nextTheme =
                            isDark ? ThemeMode.light : ThemeMode.dark;
                        ref
                            .read(themeControllerProvider.notifier)
                            .setThemeMode(nextTheme);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Logout
                    TextButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: Text(
                        'Se déconnecter',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo or Icon
                        Icon(
                          Icons.grid_view_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacing.gapL,
                        
                        // Welcome text
                        Text(
                          'Bonjour, $fullName',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapS,
                        Text(
                          'Sélectionnez votre espace de travail pour continuer',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapXxl,
                        AppSpacing.gapXl,

                        // Workspace Options
                        isDesktop
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWorkspaceCard(
                                    context: context,
                                    title: 'DUX Mobile',
                                    subtitle: 'Espace Opérationnel & Gestion',
                                    description:
                                        'Consultez vos tableaux de bord de gestion de vente, préparation de commandes et indicateurs clés.',
                                    icon: Icons.phone_android_rounded,
                                    gradientColors: [
                                      const Color(0xFF1E3C72),
                                      const Color(0xFF2A5298),
                                    ],
                                    onTap: () => context.go('/dashboard'),
                                  ),
                                  const SizedBox(width: 24),
                                  _buildWorkspaceCard(
                                    context: context,
                                    title: 'Dux Calender',
                                    subtitle: 'Espace Administration & Menus',
                                    description:
                                        'Gérez vos catégories, pages dynamiques, groupes de menus et rôles d\'utilisateurs.',
                                    icon: Icons.account_tree_outlined,
                                    gradientColors: [
                                      const Color(0xFF0F9D58),
                                      const Color(0xFF00796B),
                                    ],
                                    onTap: () => context.go('/timetree/dashboard'),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildWorkspaceCard(
                                    context: context,
                                    title: 'DUX Mobile',
                                    subtitle: 'Espace Opérationnel & Gestion',
                                    description:
                                        'Consultez vos tableaux de bord de gestion de vente, préparation de commandes et indicateurs clés.',
                                    icon: Icons.phone_android_rounded,
                                    gradientColors: [
                                      const Color(0xFF1E3C72),
                                      const Color(0xFF2A5298),
                                    ],
                                    onTap: () => context.go('/dashboard'),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildWorkspaceCard(
                                    context: context,
                                    title: 'Dux Calender',
                                    subtitle: 'Espace Administration & Menus',
                                    description:
                                        'Gérez vos catégories, pages dynamiques, groupes de menus et rôles d\'utilisateurs.',
                                    icon: Icons.account_tree_outlined,
                                    gradientColors: [
                                      const Color(0xFF0F9D58),
                                      const Color(0xFF00796B),
                                    ],
                                    onTap: () => context.go('/timetree/dashboard'),
                                  ),
                                ],
                              ),
                      ],
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

  Widget _buildWorkspaceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 750;

    return Container(
      width: isDesktop ? 340 : double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.roundedL,
        boxShadow: AppShadows.largeShadow(context),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.roundedL,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.roundedL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Top Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xxl,
                  horizontal: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Body Details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradientColors.first,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Accéder à l\'espace',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
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
}
