import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_search_bar.dart';
import 'package:dux_front/core/widgets/empty_state_widget.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/services/search_history_service.dart';
import 'package:dux_front/core/models/base_document.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:dux_front/core/theme/theme_helper.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/features/bon_preparation/presentation/widgets/scanner_overlay.dart';

class GenericDocumentListScreen<T extends BaseDocument, S> extends ConsumerStatefulWidget {
  final String title;
  final String searchHint;
  final StateNotifierProvider<StateNotifier<S>, S> stateProvider;
  
  // Data mapping from State
  final List<T> Function(S state) getItems;
  final bool Function(S state) getIsLoading;
  final String? Function(S state) getError;
  final int Function(S state) getPage;
  final bool Function(S state) getHasMore;
  final String Function(S state) getSearchQuery;
  final bool Function(S state) getIsFilterActive;
  
  // Status filter integration
  final String Function(S state)? getStatusFilter;
  final void Function(WidgetRef ref, String status)? onStatusFilterChanged;
  
  // Action callbacks
  final Future<void> Function(WidgetRef ref, {required bool refresh}) onRefresh;
  final void Function(WidgetRef ref, String query) onSearchChanged;
  final void Function(WidgetRef ref) onResetFilters;
  final void Function(WidgetRef ref, int page) onGoToPage;
  final void Function(BuildContext context, WidgetRef ref) onFilterPressed;
  final Future<String?> Function(BuildContext context)? onCustomScanPressed; // Optional barcode overlay scan action
  
  // Custom builders
  final List<Widget> Function(BuildContext context, S state, WidgetRef ref) buildFilterChips;
  final Widget Function(BuildContext context, T item, WidgetRef ref) buildItemCard;
  final String emptyStateTitle;
  final String emptyStateDescription;
  final IconData emptyStateIcon;
  final bool? isLoadingOverride;

  const GenericDocumentListScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.stateProvider,
    required this.getItems,
    required this.getIsLoading,
    required this.getError,
    required this.getPage,
    required this.getHasMore,
    required this.getSearchQuery,
    required this.getIsFilterActive,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onResetFilters,
    required this.onGoToPage,
    required this.onFilterPressed,
    this.onCustomScanPressed,
    required this.buildFilterChips,
    required this.buildItemCard,
    required this.emptyStateTitle,
    required this.emptyStateDescription,
    required this.emptyStateIcon,
    this.isLoadingOverride,
    this.getStatusFilter,
    this.onStatusFilterChanged,
  });

  @override
  ConsumerState<GenericDocumentListScreen<T, S>> createState() => _GenericDocumentListScreenState<T, S>();
}

class _GenericDocumentListScreenState<T extends BaseDocument, S> extends ConsumerState<GenericDocumentListScreen<T, S>> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(widget.stateProvider);
    final recentSearches = ref.watch(searchHistoryProvider);
    
    // Dynamic screen configurations
    final configState = ref.watch(screenConfigControllerProvider);
    final config = configState.configs[widget.title];

    final dynamicTheme = getDynamicTheme(context, config?.primaryColor);

    // Check role-based visibility
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toLowerCase() ?? '';
    
    final isAllowed = config == null || 
                      userRole == 'admin' || 
                      userRole == 'administrateur' || 
                      config.visibleRoles.map((r) => r.toLowerCase()).contains(userRole);

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(
          title: DuxAppBarTitle(title: config.pageTitle ?? widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              AppSpacing.gapL,
              Text(
                'Accès non autorisé',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              AppSpacing.gapM,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Votre profil ne dispose pas des droits nécessaires pour accéder à cet écran.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppSpacing.gapXl,
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Retour au tableau de bord'),
              ),
            ],
          ),
        ),
      );
    }
    
    final items = widget.getItems(state);
    final isLoading = widget.isLoadingOverride ?? widget.getIsLoading(state);
    final error = widget.getError(state);
    final page = widget.getPage(state);
    final hasMore = widget.getHasMore(state);
    final searchQuery = widget.getSearchQuery(state);
    final isFilterActive = widget.getIsFilterActive(state);

    if (isLoading) {
      return const DuxLoadingScreen(isFullScreen: true);
    }

    // Sync state search query with local text controller if different
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }

    final displayTitle = config?.pageTitle ?? widget.title;
    final displayHint = config?.searchHint ?? widget.searchHint;
    final displayScan = config?.enableBarcodeScanner ?? (widget.title == 'BP');

    return Theme(
      data: dynamicTheme,
      child: Scaffold(
        drawer: const DuxDrawer(),
        appBar: AppBar(
          title: DuxAppBarTitle(title: displayTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser',
              onPressed: () => widget.onRefresh(ref, refresh: true),
            ),
            IconButton(
              icon: const Icon(Icons.wifi, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () => context.go('/dashboard'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search & Filter Row
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                top: AppSpacing.m,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      hintText: displayHint,
                      recentSearches: recentSearches,
                      onChanged: (value) {
                        widget.onSearchChanged(ref, value);
                      },
                      onRecentSearchTapped: (value) {
                        widget.onSearchChanged(ref, value);
                        ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                      },
                      onSearchSubmitted: (value) {
                        if (value.isNotEmpty) {
                          ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                        }
                      },
                      onScanPressed: displayScan
                          ? () async {
                              final scanned = widget.onCustomScanPressed != null
                                  ? await widget.onCustomScanPressed!(context)
                                  : await Navigator.of(context).push<String>(
                                      MaterialPageRoute(
                                        builder: (context) => ScannerOverlay(
                                          title: "Scanner",
                                          enableSoundAlerts: config?.enableSoundAlerts ?? true,
                                          enableVibrationAlerts: config?.enableVibrationAlerts ?? true,
                                        ),
                                      ),
                                    );
                              if (scanned != null && scanned.isNotEmpty) {
                                _searchController.text = scanned;
                                widget.onSearchChanged(ref, scanned);
                                ref.read(searchHistoryProvider.notifier).addSearchQuery(scanned);
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: isFilterActive
                        ? dynamicTheme.colorScheme.primary
                        : dynamicTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => widget.onFilterPressed(context, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        width: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.tune_rounded,
                          color: isFilterActive
                              ? Colors.white
                              : dynamicTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            _buildStatusFiltersRow(dynamicTheme, config, state),
            _buildFilterChipsRow(dynamicTheme, state, isFilterActive),
  
            // Main list or state widgets
            Expanded(
              child: _buildMainContent(state, items, isLoading, error),
            ),
            
            _buildPaginationFooter(dynamicTheme, items, isLoading, page, hasMore),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFiltersRow(ThemeData theme, ScreenConfig? config, S state) {
    final statusStr = config?.statusFilters;
    if (statusStr == null || statusStr.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (widget.getStatusFilter == null || widget.onStatusFilterChanged == null) {
      return const SizedBox.shrink();
    }
    
    final currentStatus = widget.getStatusFilter!(state);
    
    // Parse mapping
    final pairs = statusStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final options = <MapEntry<String, String>>[];
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        options.add(MapEntry(parts[0].trim(), parts[1].trim()));
      }
    }
    
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: AppSpacing.s, top: AppSpacing.xs),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = currentStatus == option.key || (currentStatus.isEmpty && option.key == 'all');
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                option.value,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  widget.onStatusFilterChanged!(ref, option.key);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChipsRow(ThemeData theme, S state, bool isFilterActive) {
    final chips = widget.buildFilterChips(context, state, ref);
    if (chips.isEmpty && !isFilterActive) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        children: [
          if (isFilterActive) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Theme(
                data: theme.copyWith(canvasColor: Colors.transparent),
                child: ActionChip(
                  avatar: Icon(Icons.refresh_rounded, size: 16, color: theme.colorScheme.error),
                  label: Text(
                    'Réinitialiser',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => widget.onResetFilters(ref),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ],
          ...chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )),
        ],
      ),
    );
  }

  Widget _buildMainContent(S state, List<T> items, bool isLoading, String? error) {
    if (isLoading && items.isEmpty) {
      return _buildSkeletonList();
    }

    if (error != null && items.isEmpty) {
      return ErrorStateWidget(
        description: error,
        onRetry: () => widget.onRefresh(ref, refresh: true),
      );
    }

    if (items.isEmpty) {
      return EmptyStateWidget(
        title: widget.emptyStateTitle,
        description: widget.emptyStateDescription,
        icon: widget.emptyStateIcon,
        actionLabel: 'Réinitialiser les filtres',
        onActionPressed: () {
          _searchController.clear();
          widget.onSearchChanged(ref, '');
          widget.onResetFilters(ref);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await widget.onRefresh(ref, refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return widget.buildItemCard(context, items[index], ref);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.l),
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: AppBorderRadius.roundedL,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LoadingSkeleton(height: 20, width: 120),
                  LoadingSkeleton(height: 20, width: 80),
                ],
              ),
              AppSpacing.gapL,
              LoadingSkeleton(height: 18, width: 200),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LoadingSkeleton(height: 14, width: 100),
                  LoadingSkeleton(height: 14, width: 80),
                ],
              ),
              AppSpacing.gapL,
              Divider(height: 1),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LoadingSkeleton(height: 14, width: 80),
                  LoadingSkeleton(height: 22, width: 100),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(
    ThemeData theme,
    List<T> items,
    bool isLoading,
    int page,
    bool hasMore,
  ) {
    if (items.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: page > 1 && !isLoading
                  ? () => widget.onGoToPage(ref, page - 1)
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Page $page',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: hasMore && !isLoading
                  ? () => widget.onGoToPage(ref, page + 1)
                  : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
