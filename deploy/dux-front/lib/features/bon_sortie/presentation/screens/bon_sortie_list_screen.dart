import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_search_bar.dart';
import 'package:dux_front/core/widgets/filter_chip.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/empty_state_widget.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/core/services/search_history_service.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../controllers/bon_sortie_list_controller.dart';
import '../../domain/models/bon_sortie.dart';
import '../widgets/sortie_filter_bottom_sheet.dart';

class BonSortieListScreen extends ConsumerStatefulWidget {
  const BonSortieListScreen({super.key});

  @override
  ConsumerState<BonSortieListScreen> createState() => _BonSortieListScreenState();
}

class _BonSortieListScreenState extends ConsumerState<BonSortieListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final controller = ref.read(bonSortieListControllerProvider.notifier);
    final currentFilter = ref.read(bonSortieListControllerProvider).filter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SortieFilterBottomSheet(
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
    final state = ref.watch(bonSortieListControllerProvider);
    final recentSearches = ref.watch(searchHistoryProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'BS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(bonSortieListControllerProvider.notifier).fetchSorties(refresh: true),
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
          // Search Bar Block with filter button
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
                    hintText: 'Rechercher code, client ou représentant...',
                    recentSearches: recentSearches,
                    onChanged: (value) {
                      ref
                          .read(bonSortieListControllerProvider.notifier)
                          .updateSearchQuery(value);
                    },
                    onRecentSearchTapped: (value) {
                      ref
                          .read(bonSortieListControllerProvider.notifier)
                          .updateSearchQuery(value);
                      ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                    },
                    onSearchSubmitted: (value) {
                      if (value.isNotEmpty) {
                        ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: state.filter.advancedFilterActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _showFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      width: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.tune_rounded,
                        color: state.filter.advancedFilterActive
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFilterChipsRow(theme, state),

          // Main list content
          Expanded(
            child: _buildMainContent(state),
          ),
          _buildPaginationFooter(theme, state),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(ThemeData theme, BonSortieListState state) {
    final hasDates = state.filter.dateFrom != null && state.filter.dateTo != null;
    final activeFilters = <Widget>[];

    // 1. Date Range Chip (Always visible)
    activeFilters.add(
      Theme(
        data: theme.copyWith(canvasColor: Colors.transparent),
        child: InputChip(
          avatar: Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: hasDates ? Colors.white : theme.colorScheme.primary,
          ),
          label: Text(
            hasDates
                ? '${DateFormat('dd/MM/yy').format(state.filter.dateFrom!)} - ${DateFormat('dd/MM/yy').format(state.filter.dateTo!)}'
                : 'Période',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: hasDates ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          selected: hasDates,
          selectedColor: theme.colorScheme.primary,
          checkmarkColor: Colors.transparent,
          showCheckmark: false,
          onSelected: (_) => _selectDateRange(),
          onDeleted: hasDates
              ? () {
                  ref.read(bonSortieListControllerProvider.notifier).applyFilter(
                        state.filter.copyWith(clearDates: true),
                      );
                }
              : null,
          deleteIcon: hasDates ? const Icon(Icons.close_rounded, size: 14) : null,
          deleteIconColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: hasDates ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );

    // 2. All Documents Filter Chip
    if (!state.filter.allDocuments) {
      activeFilters.add(
        Theme(
          data: theme.copyWith(canvasColor: Colors.transparent),
          child: InputChip(
            label: const Text(
              'Documents filtrés',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            selected: true,
            selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            checkmarkColor: Colors.transparent,
            showCheckmark: false,
            onSelected: (_) {},
            onDeleted: () {
              ref.read(bonSortieListControllerProvider.notifier).applyFilter(
                    state.filter.copyWith(allDocuments: true),
                  );
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    // 3. Status Filter Chip
    if (state.filter.status != null && state.filter.status!.isNotEmpty) {
      activeFilters.add(
        Theme(
          data: theme.copyWith(canvasColor: Colors.transparent),
          child: InputChip(
            label: Text(
              'Statut: ${state.filter.status}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            selected: true,
            selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            checkmarkColor: Colors.transparent,
            showCheckmark: false,
            onSelected: (_) {},
            onDeleted: () {
              ref.read(bonSortieListControllerProvider.notifier).applyFilter(
                    state.filter.copyWith(status: ''),
                  );
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    // 4. Tier Filter Chip
    if (state.filter.tier != null && state.filter.tier!.isNotEmpty) {
      activeFilters.add(
        Theme(
          data: theme.copyWith(canvasColor: Colors.transparent),
          child: InputChip(
            label: Text(
              'Tier: ${state.filter.tier}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            selected: true,
            selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            checkmarkColor: Colors.transparent,
            showCheckmark: false,
            onSelected: (_) {},
            onDeleted: () {
              ref.read(bonSortieListControllerProvider.notifier).applyFilter(
                    state.filter.copyWith(tier: ''),
                  );
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    // 5. Representative Filter Chip
    if (state.filter.representative != null && state.filter.representative!.isNotEmpty) {
      activeFilters.add(
        Theme(
          data: theme.copyWith(canvasColor: Colors.transparent),
          child: InputChip(
            label: Text(
              'Rep: ${state.filter.representative}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            selected: true,
            selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            checkmarkColor: Colors.transparent,
            showCheckmark: false,
            onSelected: (_) {},
            onDeleted: () {
              ref.read(bonSortieListControllerProvider.notifier).applyFilter(
                    state.filter.copyWith(representative: ''),
                  );
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    final isAnyFilterActive = hasDates ||
        !state.filter.allDocuments ||
        (state.filter.status != null && state.filter.status!.isNotEmpty) ||
        (state.filter.tier != null && state.filter.tier!.isNotEmpty) ||
        (state.filter.representative != null && state.filter.representative!.isNotEmpty);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        children: [
          if (isAnyFilterActive) ...[
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
                  onPressed: () {
                    ref.read(bonSortieListControllerProvider.notifier).clearFilters();
                  },
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
          ...activeFilters.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )),
        ],
      ),
    );
  }

  Widget _buildMainContent(BonSortieListState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.sorties.isEmpty) {
      return _buildSkeletonList();
    }

    if (state.error != null && state.sorties.isEmpty) {
      return ErrorStateWidget(
        description: state.error!,
        onRetry: () =>
            ref.read(bonSortieListControllerProvider.notifier).fetchSorties(refresh: true),
      );
    }

    if (state.sorties.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucun bon de sortie trouvé',
        description: 'Modifiez vos filtres ou effectuez une recherche.',
        icon: Icons.output_outlined,
        actionLabel: 'Réinitialiser les filtres',
        onActionPressed: () {
          _searchController.clear();
          ref.read(bonSortieListControllerProvider.notifier).updateSearchQuery('');
          ref.read(bonSortieListControllerProvider.notifier).clearFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await ref
            .read(bonSortieListControllerProvider.notifier)
            .fetchSorties(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: state.sorties.length,
        itemBuilder: (context, index) {
          final sortie = state.sorties[index];
          final formattedDate =
              DateFormat('dd/MM/yyyy').format(sortie.date);
          final formattedAmount = NumberFormat.currency(
            locale: 'fr_TN',
            symbol: 'TND',
            decimalDigits: 3,
          ).format(sortie.amount);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            child: InkWell(
              onTap: () async {
                await context.pushNamed(
                  RouteNames.bonSortieDetail,
                  pathParameters: {'id': sortie.id},
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with Status dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _parseStatusColor(sortie.statusColor) ??
                                  Colors.blueAccent.shade200,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            sortie.customerName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Key-Value rows
                    Text.rich(
                      TextSpan(
                        text: 'Code: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: sortie.documentCode,
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Représentant: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: sortie.representative.isNotEmpty
                                ? sortie.representative
                                : '—',
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Statut: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: sortie.status,
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Date: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: formattedDate,
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Montant HT: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: formattedAmount,
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons (Bottom Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: Icons.visibility_outlined,
                          color: const Color(0xFF62A0EA),
                          onTap: () {
                            context.pushNamed(
                              RouteNames.bonSortieDetail,
                              pathParameters: {'id': sortie.id},
                            );
                          },
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

  static Color? _parseStatusColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    final clean = colorStr.trim().toLowerCase();

    if (clean.startsWith('rgba')) {
      try {
        final match = RegExp(
                r'rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)')
            .firstMatch(clean);
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
        final match =
            RegExp(r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
                .firstMatch(clean);
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

  Widget _buildPaginationFooter(ThemeData theme, BonSortieListState state) {
    if (state.sorties.isEmpty && !state.isLoading) {
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
              onPressed: state.page > 1 && !state.isLoading
                  ? () => ref.read(bonSortieListControllerProvider.notifier).goToPage(state.page - 1)
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Page ${state.page}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: state.hasMore && !state.isLoading
                  ? () => ref.read(bonSortieListControllerProvider.notifier).goToPage(state.page + 1)
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

  Future<void> _selectDateRange() async {
    final controller = ref.read(bonSortieListControllerProvider.notifier);
    final state = ref.read(bonSortieListControllerProvider);
    final filter = state.filter;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: filter.dateFrom != null && filter.dateTo != null
          ? DateTimeRange(start: filter.dateFrom!, end: filter.dateTo!)
          : DateTimeRange(
              start: DateTime(DateTime.now().year, DateTime.now().month, 1),
              end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6), // Blue selection
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B), // Dark blue surface like reference
              onSurface: Colors.white,
              secondary: Color(0xFF60A5FA),
            ),
            dialogBackgroundColor: const Color(0xFF1E293B),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.applyFilter(
        filter.copyWith(
          dateFrom: picked.start,
          dateTo: picked.end,
        ),
      );
    }
  }

}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
