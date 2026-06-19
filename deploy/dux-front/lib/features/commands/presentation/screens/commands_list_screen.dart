import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/generic_document_list_screen.dart';
import '../controllers/commands_controller.dart';
import '../../domain/models/command.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../command_details/presentation/utils/pdf_generation_helper.dart';
import '../../../command_details/data/repositories/command_details_repository.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class CommandsListScreen extends ConsumerWidget {
  const CommandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return GenericDocumentListScreen<Command, CommandsState>(
      title: 'BC',
      searchHint: 'Search code, customer or representative...',
      stateProvider: commandsControllerProvider,
      
      // State Getters
      getItems: (state) => state.commands,
      getIsLoading: (state) => state.isLoading,
      getError: (state) => state.error,
      getPage: (state) => state.page,
      getHasMore: (state) => state.hasMore,
      getSearchQuery: (state) => state.searchQuery,
      getIsFilterActive: (state) => state.filter.advancedFilterActive,
      
      // Callbacks
      onRefresh: (ref, {required refresh}) => ref.read(commandsControllerProvider.notifier).fetchCommands(refresh: refresh),
      onSearchChanged: (ref, query) => ref.read(commandsControllerProvider.notifier).updateSearchQuery(query),
      onResetFilters: (ref) => ref.read(commandsControllerProvider.notifier).clearFilters(),
      onGoToPage: (ref, page) => ref.read(commandsControllerProvider.notifier).goToPage(page),
      
      onFilterPressed: (context, ref) {
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
      },
      
      // UI Customizations
      emptyStateTitle: 'Aucune commande trouvée',
      emptyStateDescription: 'Essayez de modifier votre recherche ou vos filtres pour trouver des résultats.',
      emptyStateIcon: Icons.search_off_rounded,
      
      buildFilterChips: (context, state, ref) {
        final hasDates = state.filter.dateFrom != null && state.filter.dateTo != null;
        final activeFilters = <Widget>[];

        // 1. Date Range Chip
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
              onSelected: (_) => _selectDateRange(context, ref, state.filter),
              onDeleted: hasDates
                  ? () {
                      ref.read(commandsControllerProvider.notifier).applyFilter(
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
                  ref.read(commandsControllerProvider.notifier).applyFilter(
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
                  ref.read(commandsControllerProvider.notifier).applyFilter(
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
                  ref.read(commandsControllerProvider.notifier).applyFilter(
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
                  ref.read(commandsControllerProvider.notifier).applyFilter(
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

        return activeFilters;
      },
      
      buildItemCard: (context, command, ref) {
        final configState = ref.watch(screenConfigControllerProvider);
        final bcConfig = configState.configs['BC'];
        final showPrint = bcConfig?.enablePdfPrinting ?? true;

        final authState = ref.watch(authControllerProvider);
        final userRole = authState.user?.role.toLowerCase() ?? '';
        final isOperator = userRole == 'operateur' || userRole == 'opérateur';
        final hidePrices = (bcConfig?.hidePricesForOperateurs ?? false) && isOperator;

        final formattedDate = DateFormat('dd/MM/yyyy').format(command.date);
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
                            color: _parseStatusColor(command.statusColor) ?? Colors.greenAccent.shade200,
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
                  if (!hidePrices) ...[
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
                  ],

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
                      if (showPrint) ...[
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, CommandFilter filter) async {
    final controller = ref.read(commandsControllerProvider.notifier);

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
              surface: Color(0xFF1E293B),
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

  static Color? _parseStatusColor(String? colorStr) {
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
