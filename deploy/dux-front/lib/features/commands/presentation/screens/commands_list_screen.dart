import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_search_bar.dart';
import 'package:dux_front/core/widgets/filter_chip.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/skeleton_card.dart';
import 'package:dux_front/core/widgets/empty_state_widget.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import '../controllers/commands_controller.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'package:dux_front/core/services/search_history_service.dart';
import '../../../command_details/presentation/utils/pdf_generation_helper.dart';
import '../../../command_details/data/repositories/command_details_repository.dart';

class CommandsListScreen extends ConsumerStatefulWidget {
  const CommandsListScreen({super.key});

  @override
  ConsumerState<CommandsListScreen> createState() => _CommandsListScreenState();
}

class _CommandsListScreenState extends ConsumerState<CommandsListScreen> {
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
      ref.read(commandsControllerProvider.notifier).loadNextPage();
    }
  }

  void _showFilterSheet() {
    final controller = ref.read(commandsControllerProvider.notifier);
    final currentFilter = ref.read(commandsControllerProvider).filter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterBottomSheet(
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
    final state = ref.watch(commandsControllerProvider);
    final recentSearches = ref.watch(searchHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'BC'),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: state.filter.advancedFilterActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            tooltip: 'Filtrer les commandes',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true),
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
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search code, customer or representative...',
              recentSearches: recentSearches,
              onChanged: (value) {
                ref.read(commandsControllerProvider.notifier).updateSearchQuery(value);
              },
              onRecentSearchTapped: (value) {
                ref.read(commandsControllerProvider.notifier).updateSearchQuery(value);
                ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
              },
              onSearchSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref.read(searchHistoryProvider.notifier).addSearchQuery(value);
                }
              },
            ),
          ),

          // Horizontal Filter Status Chips
          _buildFilterChips(state),

          // Main list or states
          Expanded(
            child: _buildMainContent(state),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterChips(CommandsState state) {
    final activeFilters = <Widget>[];

    if (!state.filter.allDocuments) {
      activeFilters.add(
        AppFilterChip(
          label: 'Filtered Documents',
          isSelected: true,
          onSelected: (_) {
            ref.read(commandsControllerProvider.notifier).applyFilter(
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
            ref.read(commandsControllerProvider.notifier).applyFilter(
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
            ref.read(commandsControllerProvider.notifier).applyFilter(
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
            ref.read(commandsControllerProvider.notifier).applyFilter(
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
            ref.read(commandsControllerProvider.notifier).applyFilter(
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
                ref.read(commandsControllerProvider.notifier).clearFilters();
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

  Widget _buildMainContent(CommandsState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.commands.isEmpty) {
      return _buildSkeletonList();
    }

    if (state.error != null && state.commands.isEmpty) {
      return ErrorStateWidget(
        description: state.error!,
        onRetry: () => ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true),
      );
    }

    if (state.commands.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucune commande trouvée',
        description: 'Essayez de modifier votre recherche ou vos filtres pour trouver des résultats.',
        icon: Icons.search_off_rounded,
        actionLabel: 'Réinitialiser les filtres',
        onActionPressed: () {
          _searchController.clear();
          ref.read(commandsControllerProvider.notifier).updateSearchQuery('');
          ref.read(commandsControllerProvider.notifier).clearFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: state.commands.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.commands.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final command = state.commands[index];
          final formattedDate = DateFormat('dd/MM/yyyy').format(command.date);
          final formattedAmount = NumberFormat.currency(
            locale: 'fr_TN',
            symbol: 'TND',
            decimalDigits: 3,
          ).format(command.amount);
          final formattedTTC = NumberFormat.currency(
            locale: 'fr_TN',
            symbol: 'TND',
            decimalDigits: 3,
          ).format(command.amountTTC);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            child: InkWell(
              onTap: () {
                context.go('/commands/details/${command.id}');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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
                              color: _StatusBadge.parseColor(command.statusColor) ?? Colors.greenAccent.shade200,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            command.customerName.toUpperCase(),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: command.documentCode,
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Représentant: ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: command.representative.isNotEmpty ? command.representative : '—',
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Statut: ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: command.status,
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Date: ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Prix TTC: ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(
                            text: formattedTTC,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                          color: const Color(0xFF62A0EA), // Blue
                          onTap: () => context.go('/commands/details/${command.id}'),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.print_rounded,
                          color: const Color(0xFFF6D32D), // Yellow
                          onTap: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Préparation du document PDF...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            try {
                              final repo = ref.read(commandDetailsRepositoryProvider);
                              final details = await repo.getCommandDetails(command.id);
                              await PdfGenerationHelper.printCommand(details);
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Erreur: Impossible de charger les détails')),
                              );
                            }
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const SkeletonCard();
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String? apiColor;

  const _StatusBadge({
    required this.label,
  }) : apiColor = null;

  static Color? parseColor(String? colorStr) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseColor(apiColor) ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppBorderRadius.roundedS,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
