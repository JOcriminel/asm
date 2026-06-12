import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  }

  @override
  void dispose() {
    _repController.dispose();
    _docCodeController.dispose();
    _articleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final theme = Theme.of(context);
    final initialDate = isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now());
    
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = selected;
        } else {
          _dateTo = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapL,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            AppSpacing.gapM,

            // All Documents Toggle
            SwitchListTile.adaptive(
              title: const Text('All Documents'),
              subtitle: Text(
                'Show all orders regardless of status',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              value: _allDocuments,
              onChanged: (value) {
                setState(() {
                  _allDocuments = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),

            // Advanced Filters Toggle
            SwitchListTile.adaptive(
              title: const Text('Advanced Filters'),
              subtitle: Text(
                'Unlock granular fields, reps, and articles',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              value: _advancedFilterActive,
              onChanged: (value) {
                setState(() {
                  _advancedFilterActive = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            AppSpacing.gapM,

            if (_advancedFilterActive) ...[
              // Date fields
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _dateFrom == null ? 'Date From' : DateFormat('yyyy-MM-dd').format(_dateFrom!),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                      ),
                    ),
                  ),
                  AppSpacing.gapM,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _dateTo == null ? 'Date To' : DateFormat('yyyy-MM-dd').format(_dateTo!),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                      ),
                    ),
                  ),
                ],
              ),
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

              // Tier Dropdown
              DropdownButtonFormField<String>(
                value: _selectedTier,
                decoration: const InputDecoration(
                  labelText: 'Customer Tier',
                  prefixIcon: Icon(Icons.trending_up, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 'A-Tier', child: Text('A-Tier')),
                  DropdownMenuItem(value: 'B-Tier', child: Text('B-Tier')),
                  DropdownMenuItem(value: 'C-Tier', child: Text('C-Tier')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTier = value;
                  });
                },
              ),
              AppSpacing.gapL,

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Order Status',
                  prefixIcon: Icon(Icons.verified_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'validated', child: Text('Validated')),
                  DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              AppSpacing.gapXl,
            ],

            PrimaryButton(
              text: 'Apply Filters',
              onPressed: () {
                final applied = CommandFilter(
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  tier: _selectedTier,
                  representative: _repController.text,
                  documentCode: _docCodeController.text,
                  status: _selectedStatus,
                  allDocuments: _allDocuments,
                  articleFilter: _articleController.text,
                  advancedFilterActive: _advancedFilterActive,
                );
                widget.onApply(applied);
                Navigator.pop(context);
              },
            ),
            AppSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
