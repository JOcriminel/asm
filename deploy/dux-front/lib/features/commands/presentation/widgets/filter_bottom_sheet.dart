import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_text_field.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import 'package:dux_front/features/commands/domain/models/command.dart';

class FilterBottomSheet extends StatefulWidget {
  final CommandFilter currentFilter;
  final ValueChanged<CommandFilter> onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedTier;
  String? _selectedStatus;
  final _repController = TextEditingController();
  final _docCodeController = TextEditingController();
  final _articleController = TextEditingController();
  bool _allDocuments = true;
  bool _advancedFilterActive = false;
  CommandSortOrder _sortOrder = CommandSortOrder.dateDesc;

  @override
  void initState() {
    super.initState();
    final filter = widget.currentFilter;
    _dateFrom = filter.dateFrom;
    _dateTo = filter.dateTo;
    _selectedTier = filter.tier;
    _selectedStatus = filter.status;
    _repController.text = filter.representative ?? '';
    _docCodeController.text = filter.documentCode ?? '';
    _articleController.text = filter.articleFilter ?? '';
    _allDocuments = filter.allDocuments;
    _advancedFilterActive = filter.advancedFilterActive;
    _sortOrder = filter.sortOrder;
  }

  @override
  void dispose() {
    _repController.dispose();
    _docCodeController.dispose();
    _articleController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
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
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  Widget _buildDatePickerCard(ThemeData theme) {
    final hasDates = _dateFrom != null && _dateTo != null;
    return InkWell(
      onTap: () => _selectDateRange(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDates ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              color: hasDates ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Période',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasDates
                        ? '${DateFormat('dd/MM/yyyy').format(_dateFrom!)} - ${DateFormat('dd/MM/yyyy').format(_dateTo!)}'
                        : 'Select Date Range',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasDates ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDates)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  });
                },
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tiers = ['A-Tier', 'B-Tier', 'C-Tier'];
    final statuses = [
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'validated', 'label': 'Validated'},
      {'value': 'delivered', 'label': 'Delivered'},
      {'value': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapL,

            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrer les Commandes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                      _selectedTier = null;
                      _selectedStatus = null;
                      _repController.clear();
                      _docCodeController.clear();
                      _articleController.clear();
                      _allDocuments = true;
                      _advancedFilterActive = false;
                      _sortOrder = CommandSortOrder.dateDesc;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Réinitialiser',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.gapL,

            // All Documents Toggle Card
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'All Documents',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Show all orders regardless of status',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: _allDocuments,
                onChanged: (value) {
                  setState(() {
                    _allDocuments = value;
                  });
                },
              ),
            ),
            AppSpacing.gapL,

            // Sorting Selection
            DropdownButtonFormField<CommandSortOrder>(
              isExpanded: true,
              initialValue: _sortOrder,
              decoration: const InputDecoration(
                labelText: 'Trier par',
                prefixIcon: Icon(Icons.sort_rounded, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: CommandSortOrder.dateDesc, child: Text('Date (Plus récent)')),
                DropdownMenuItem(value: CommandSortOrder.dateAsc, child: Text('Date (Plus ancien)')),
                DropdownMenuItem(value: CommandSortOrder.amountDesc, child: Text('Montant (Décroissant)')),
                DropdownMenuItem(value: CommandSortOrder.amountAsc, child: Text('Montant (Croissant)')),
                DropdownMenuItem(value: CommandSortOrder.nameAsc, child: Text('Client (A-Z)')),
                DropdownMenuItem(value: CommandSortOrder.nameDesc, child: Text('Client (Z-A)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortOrder = value;
                  });
                }
              },
            ),
            AppSpacing.gapL,

            // Advanced Filters Toggle Card
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Advanced Filters',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Unlock granular fields, reps, and articles',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: _advancedFilterActive,
                onChanged: (value) {
                  setState(() {
                    _advancedFilterActive = value;
                  });
                },
              ),
            ),
            AppSpacing.gapL,

            if (_advancedFilterActive) ...[
              // Date Card
              _buildDatePickerCard(theme),
              AppSpacing.gapL,

              // Document Code Input
              AppTextField(
                controller: _docCodeController,
                labelText: 'Document Code',
                prefixIcon: Icons.qr_code,
              ),
              AppSpacing.gapL,

              // Representative Field
              AppTextField(
                controller: _repController,
                labelText: 'Representative Name',
                prefixIcon: Icons.badge_outlined,
              ),
              AppSpacing.gapL,

              // Article Filter
              AppTextField(
                controller: _articleController,
                labelText: 'Filter by Article Name/SKU',
                prefixIcon: Icons.category_outlined,
              ),
              AppSpacing.gapL,

              // Customer Tier selection chips
              Text(
                'Customer Tier',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tiers.map((tier) {
                  final isSelected = _selectedTier == tier;
                  return ChoiceChip(
                    label: Text(
                      tier,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTier = selected ? tier : null;
                      });
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapL,

              // Order Status selection chips
              Text(
                'Order Status',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: statuses.map((status) {
                  final val = status['value']!;
                  final label = status['label']!;
                  final isSelected = _selectedStatus == val;
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? val : null;
                      });
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapXl,
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: 'Apply Filters',
                onPressed: () {
                  final applied = CommandFilter(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    tier: _selectedTier,
                    representative: _repController.text.trim(),
                    documentCode: _docCodeController.text.trim(),
                    status: _selectedStatus,
                    allDocuments: _allDocuments,
                    articleFilter: _articleController.text.trim(),
                    advancedFilterActive: _advancedFilterActive,
                    sortOrder: _sortOrder,
                  );
                  widget.onApply(applied);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
