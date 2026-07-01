import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/theme/theme_controller.dart';
import 'package:dux_front/core/services/tutorial_service.dart';

class IntroWalkthroughScreen extends ConsumerStatefulWidget {
  const IntroWalkthroughScreen({super.key});

  @override
  ConsumerState<IntroWalkthroughScreen> createState() => _IntroWalkthroughScreenState();
}

class _IntroWalkthroughScreenState extends ConsumerState<IntroWalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeWalkthrough() async {
    await ref.read(tutorialServiceProvider).setSeenIntro(true);
    if (mounted) {
      context.go('/workspace-selector');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

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
              // Header with Skip button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.m,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeWalkthrough,
                    child: Text(
                      'Passer',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Slide PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildSlide(
                      context: context,
                      theme: theme,
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF2196F3),
                      title: 'Bienvenue sur DUX Mobile',
                      description:
                          'Gérez vos bons de préparation (BP), bons de sortie (BS), et suivez l\'état d\'avancement de votre logistique et entrepôt en temps réel.',
                    ),
                    _buildSlide(
                      context: context,
                      theme: theme,
                      icon: Icons.account_tree_outlined,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'Découvrez Dux Calender',
                      description:
                          'Planifiez vos calendriers, gérez les rôles, permissions et restez au fait des plannings d\'équipe et événements importants.',
                    ),
                  ],
                ),
              ),
              
              // Bottom Indicator and Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicators
                    Row(
                      children: List.generate(
                        2,
                        (index) => _buildIndicator(index, isDark, theme),
                      ),
                    ),
                    
                    // Next / Finish Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == 1) {
                          _completeWalkthrough();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl * 1.5,
                          vertical: AppSpacing.m * 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == 1 ? 'Commencer' : 'Suivant',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 1
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
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

  Widget _buildSlide({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, bool isDark, ThemeData theme) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : (isDark ? Colors.grey[700] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
