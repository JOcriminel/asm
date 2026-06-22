import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/generic_document_list_screen.dart';
import '../controllers/bon_preparation_list_controller.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';
import '../../domain/models/bon_preparation.dart';
import '../widgets/preparation_filter_bottom_sheet.dart';
import '../widgets/scanner_overlay.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import '../../../checklist/presentation/controllers/checklist_response_controller.dart';

class BonPreparationListScreen extends ConsumerWidget {
  const BonPreparationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(bonPreparationListControllerProvider);
    final preparations = state.preparations;

    final isListLoading = state.isLoading;

    return GenericDocumentListScreen<BonPreparation, BonPreparationListState>(
      title: 'BP',
      searchHint: 'Search code, customer or representative...',
      stateProvider: bonPreparationListControllerProvider,
      isLoadingOverride: isListLoading,
      
      // State Getters
      getItems: (state) => state.preparations,
      getIsLoading: (state) => state.isLoading,
      getError: (state) => state.error,
      getPage: (state) => state.page,
      getHasMore: (state) => state.hasMore,
      getSearchQuery: (state) => state.searchQuery,
      getIsFilterActive: (state) => state.filter.advancedFilterActive,
      
      getStatusFilter: (state) => state.filter.status ?? '',
      onStatusFilterChanged: (ref, status) {
        final controller = ref.read(bonPreparationListControllerProvider.notifier);
        final currentFilter = ref.read(bonPreparationListControllerProvider).filter;
        controller.applyFilter(currentFilter.copyWith(status: status));
      },
      
      // Callbacks
      onRefresh: (ref, {required refresh}) => ref.read(bonPreparationListControllerProvider.notifier).fetchPreparations(refresh: refresh),
      onSearchChanged: (ref, query) => ref.read(bonPreparationListControllerProvider.notifier).updateSearchQuery(query),
      onResetFilters: (ref) => ref.read(bonPreparationListControllerProvider.notifier).clearFilters(),
      onGoToPage: (ref, page) => ref.read(bonPreparationListControllerProvider.notifier).goToPage(page),
      
      onFilterPressed: (context, ref) {
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
      },
      
      onCustomScanPressed: (context) async {
        final bpConfig = ref.read(screenConfigControllerProvider).configs['BP'];
        return await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => ScannerOverlay(
              title: 'Scanner un Bon de Préparation',
              enableSoundAlerts: bpConfig?.enableSoundAlerts ?? true,
              enableVibrationAlerts: bpConfig?.enableVibrationAlerts ?? true,
            ),
          ),
        );
      },
      
      // UI Customizations
      emptyStateTitle: 'Aucune préparation trouvée',
      emptyStateDescription: 'Modifiez vos filtres ou effectuez une recherche.',
      emptyStateIcon: Icons.inventory_2_outlined,
      
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
                      ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
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
                  ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
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
                  ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
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
                  ref.read(bonPreparationListControllerProvider.notifier).applyFilter(
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
      
      buildItemCard: (context, preparation, ref) {
        var docType = preparation.documentTypeCode.isNotEmpty ? preparation.documentTypeCode : 'BP';
        if (docType == 'DPR') docType = 'BP';
        final showSN = ref.watch(screenConfigControllerProvider).configs[docType]?.enableSerialNumberTracking ?? true;
        final formattedDate = DateFormat('dd/MM/yyyy').format(preparation.date);
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          child: InkWell(
            onTap: () async {
              debugPrint('Tapped preparation card: ${preparation.id}');
              await context.pushNamed(
                RouteNames.bonPreparationDetail,
                pathParameters: {'id': preparation.id},
              );
              ref.invalidate(snCountProvider(preparation.id));
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
                            color: _parseStatusColor(preparation.statusColor) ?? Colors.greenAccent.shade200,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          preparation.customerName.toUpperCase(),
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
                          text: preparation.documentCode,
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
                          text: preparation.representative.isNotEmpty ? preparation.representative : '—',
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
                          text: preparation.status,
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
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (showSN)
                        Consumer(
                          builder: (context, ref, child) {
                            final snCountAsync = ref.watch(snCountProvider(preparation.id));
                            return snCountAsync.when(
                              data: (updatedPrep) {
                                if (updatedPrep == null) return const SizedBox.shrink();
                                
                                final scanned = updatedPrep.totalScannedSerialNumbers;
                                final required = updatedPrep.totalRequiredSerialNumbers;
                                
                                final isComplete = scanned == required && required > 0;
                                final isOverscan = scanned > required;
                                
                                Color bgColor = Colors.orange.shade50;
                                Color borderColor = Colors.orange.shade300;
                                Color textColor = Colors.orange.shade700;

                                if (isOverscan) {
                                  bgColor = Colors.red.shade50;
                                  borderColor = Colors.red.shade300;
                                  textColor = Colors.red.shade700;
                                } else if (isComplete) {
                                  bgColor = Colors.green.shade50;
                                  borderColor = Colors.green.shade300;
                                  textColor = Colors.green.shade700;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOverscan ? Icons.warning_amber_rounded : Icons.qr_code_scanner, 
                                          size: 14, 
                                          color: textColor
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'SN: $scanned / $required',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (_, _) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      Consumer(
                        builder: (context, ref, child) {
                          var docType = preparation.documentTypeCode.isNotEmpty ? preparation.documentTypeCode : 'BP';
                          if (docType == 'DPR') docType = 'BP';
                          final configsState = ref.watch(screenConfigControllerProvider);
                          final config = configsState.configs[docType];
                          final isChecklistEnabled = config?.enableChecklistTracking ?? false;
                          if (!isChecklistEnabled) return const SizedBox.shrink();

                          final countAsync = ref.watch(documentChecklistCountProvider('${preparation.id}:$docType'));
                          return countAsync.when(
                            data: (count) {
                              if (count.total == 0) return const SizedBox.shrink();
                              
                              final checked = count.checked;
                              final total = count.total;
                              final isComplete = checked == total && total > 0;
                              
                              Color bgColor;
                              Color borderColor;
                              Color textColor;

                              if (checked == 0) {
                                bgColor = Colors.red.shade50;
                                borderColor = Colors.red.shade300;
                                textColor = Colors.red.shade700;
                              } else if (isComplete) {
                                bgColor = Colors.green.shade50;
                                borderColor = Colors.green.shade300;
                                textColor = Colors.green.shade700;
                              } else {
                                bgColor = Colors.orange.shade50;
                                borderColor = Colors.orange.shade300;
                                textColor = Colors.orange.shade700;
                              }

                              return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isComplete ? Icons.check_circle_outline : (checked == 0 ? Icons.playlist_add : Icons.playlist_add_check), 
                                          size: 14, 
                                          color: textColor
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tasks ($checked/$total)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Action Buttons (Bottom Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.visibility_outlined,
                        color: const Color(0xFF62A0EA), // Blue
                        onTap: () {
                          context.pushNamed(
                            RouteNames.bonPreparationDetail,
                            pathParameters: {'id': preparation.id},
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
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, BonPreparationFilter filter) async {
    final controller = ref.read(bonPreparationListControllerProvider.notifier);

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
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
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

final snCountProvider = FutureProvider.family<BonPreparation?, String>((ref, id) async {
  final repo = ref.read(bonPreparationRepositoryProvider);
  
  final details = await ref.watch(bonPreparationDetailsProvider(id).future);
  
  if (!details.requiresSerialNumbers) return null;

  // Fetch actual SNs for the lines
  final updatedArticles = await Future.wait(details.articles.map((article) async {
    if (article.hasSerialNumbers) {
      int snRetries = 3;
      while (snRetries > 0) {
        try {
          final sns = await repo.getSerialNumbersByBonSort(
            article.id, 
            productCode: article.code,
            lineId: article.id,
          );
          return article.copyWith(serialNumbers: sns);
        } catch (_) {
          snRetries--;
          if (snRetries == 0) return article;
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    }
    return article;
  }));

  return details.copyWith(articles: updatedArticles);
});

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
