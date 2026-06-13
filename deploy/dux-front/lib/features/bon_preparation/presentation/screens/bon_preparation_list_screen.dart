import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_search_bar.dart';
import 'package:dux_front/core/widgets/filter_chip.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/empty_state_widget.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/services/search_history_service.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../controllers/bon_preparation_list_controller.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';
import '../widgets/preparation_filter_bottom_sheet.dart';

class BonPreparationListScreen extends ConsumerStatefulWidget {
  const BonPreparationListScreen({super.key});

  @override
  ConsumerState<BonPreparationListScreen> createState() => _BonPreparationListScreenState();
}

class _BonPreparationListScreenState extends ConsumerState<BonPreparationListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(bonPreparationListControllerProvider.notifier).loadNextPage();
    }
  }

  void _showFilterSheet() {
    final controller = ref.read(bonPreparationListControllerProvider.notifier);
    final currentFilter = ref.read(bonPreparationListControllerProvider).filter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PreparationFilterBottomSheet(
          currentFilter: currentFilter,
          onApply: (newFilter) {
            controller.applyFilter(newFilter);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(bonPreparationListControllerProvider);
    final recentSearches = ref.watch(searchHistoryProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Bons de Préparation'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: state.filter.advancedFilterActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            tooltip: 'Filtrer les pièces',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(bonPreparationListControllerProvider.notifier).fetchPreparations(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search code, customer or representative...',
              recentSearches: recentSearches,
              onChanged: (value) {
                ref.read(bonPreparationListControllerProvider.notifier).updateSearchQuery(value);
              },
              onRecentSearchTapped: (value) {
                ref.read(bonPreparationListControllerProvider.notifier).updateSearchQuery(value);
                ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
              },
              onSearchSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                }
              },
            ),
          ),

          // Horizontal Filter chips
          _buildFilterChips(state),

          // Main list content
          Expanded(
            child: _buildMainContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BonPreparationListState state) {
    final activeFilters = <Widget>[];

    if (!state.filter.allDocuments) {
      activeFilters.add(
        AppFilterChip(
          label: 'Filtered Documents',
          isSelected: true,
          onSelected: (_) {
            ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
                  state.filter.copyWith(allDocuments: true),
                );
          },
        ),
      );
    }

    if (state.filter.status != null && state.filter.status!.isNotEmpty) {
      activeFilters.add(
        AppFilterChip(
          label: 'Status: ${state.filter.status}',
          isSelected: true,
          onSelected: (_) {
            ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
                  state.filter.copyWith(status: ''),
                );
          },
        ),
      );
    }

    if (state.filter.tier != null && state.filter.tier!.isNotEmpty) {
      activeFilters.add(
        AppFilterChip(
          label: 'Tier: ${state.filter.tier}',
          isSelected: true,
          onSelected: (_) {
            ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
                  state.filter.copyWith(tier: ''),
                );
          },
        ),
      );
    }

    if (state.filter.representative != null && state.filter.representative!.isNotEmpty) {
      activeFilters.add(
        AppFilterChip(
          label: 'Rep: ${state.filter.representative}',
          isSelected: true,
          onSelected: (_) {
            ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
                  state.filter.copyWith(representative: ''),
                );
          },
        ),
      );
    }

    if (state.filter.dateFrom != null || state.filter.dateTo != null) {
      activeFilters.add(
        AppFilterChip(
          label: 'Custom Dates',
          isSelected: true,
          onSelected: (_) {
            ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
                  state.filter.copyWith(clearDates: true),
                );
          },
        ),
      );
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s),
            child: ActionChip(
              avatar: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear Filters'),
              onPressed: () {
                ref.read(bonPreparationListControllerProvider.notifier).clearFilters();
              },
            ),
          ),
          ...activeFilters.map((w) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: w,
              )),
        ],
      ),
    );
  }

  Widget _buildMainContent(BonPreparationListState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.preparations.isEmpty) {
      return _buildSkeletonList();
    }

    if (state.error != null && state.preparations.isEmpty) {
      return ErrorStateWidget(
        description: state.error!,
        onRetry: () => ref.read(bonPreparationListControllerProvider.notifier).fetchPreparations(refresh: true),
      );
    }

    if (state.preparations.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucune préparation trouvée',
        description: 'Modifiez vos filtres ou effectuez une recherche.',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Réinitialiser les filtres',
        onActionPressed: () {
          _searchController.clear();
          ref.read(bonPreparationListControllerProvider.notifier).updateSearchQuery('');
          ref.read(bonPreparationListControllerProvider.notifier).clearFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bonPreparationListControllerProvider.notifier).fetchPreparations(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: state.preparations.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.preparations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final preparation = state.preparations[index];
          final formattedDate = DateFormat('dd/MM/yyyy').format(preparation.date);
          final formattedAmount = NumberFormat.currency(
            locale: 'fr_TN',
            symbol: 'TND',
            decimalDigits: 3,
          ).format(preparation.amount);
          final formattedTTC = NumberFormat.currency(
            locale: 'fr_TN',
            symbol: 'TND',
            decimalDigits: 3,
          ).format(preparation.amountTTC);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.l),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                debugPrint('Tapped preparation card: ${preparation.id}');
                context.pushNamed(
                  RouteNames.bonPreparationDetail,
                  pathParameters: {'id': preparation.id},
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: AppBorderRadius.roundedL,
                  border: Border.all(color: theme.colorScheme.outline, width: 1),
                  boxShadow: AppShadows.softShadow(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preparation.documentCode,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (preparation.documentType.isNotEmpty)
                                Text(
                                  preparation.documentType,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        AppSpacing.gapS,
                        _StatusBadge(
                          label: preparation.status,
                          apiColor: preparation.statusColor,
                        ),
                      ],
                    ),
                    AppSpacing.gapM,
                    Text(
                      preparation.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapS,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: theme.colorScheme.secondary),
                            AppSpacing.gapXs,
                            Text(
                              preparation.representative.isNotEmpty
                                  ? preparation.representative
                                  : '—',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final snCountAsync = ref.watch(snCountProvider(preparation.id));
                            return snCountAsync.when(
                              data: (snCount) {
                                if (snCount == null) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: AppBorderRadius.roundedS,
                                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        snCount,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapM,
                                  ],
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.only(right: AppSpacing.m),
                                child: SizedBox(
                                  width: 12, 
                                  height: 12, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapL,
                    const Divider(height: 1),
                    AppSpacing.gapM,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Montant HT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              formattedAmount,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total TTC',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              formattedTTC,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
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
}

final snCountProvider = FutureProvider.family<String?, String>((ref, id) async {
  final repo = ref.read(bonPreparationRepositoryProvider);
  final details = await repo.getBonPreparationDetails(id);
  if (!details.requiresSerialNumbers) return null;
  return 'SN (${details.totalScannedSerialNumbers}/${details.totalRequiredSerialNumbers})';
});

class _StatusBadge extends StatelessWidget {
  final String label;
  final String? apiColor;

  const _StatusBadge({
    required this.label,
    this.apiColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsedColor = _parseColor(apiColor);
    
    if (parsedColor == null) {
      return StatusBadge(status: label);
    }

    final bg = parsedColor.withValues(alpha: 0.12);
    final fg = parsedColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.roundedFull,
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    final clean = colorStr.trim().toLowerCase();
    
    if (clean.startsWith('rgba')) {
      try {
        final match = RegExp(r'rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)').firstMatch(clean);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          final a = double.parse(match.group(4)!);
          return Color.fromARGB((a * 255).round(), r, g, b);
        }
      } catch (_) {}
    }
    
    if (clean.startsWith('rgb')) {
      try {
        final match = RegExp(r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)').firstMatch(clean);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          return Color.fromARGB(255, r, g, b);
        }
      } catch (_) {}
    }

    if (clean.startsWith('#')) {
      try {
        final hex = clean.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    return null;
  }
}
