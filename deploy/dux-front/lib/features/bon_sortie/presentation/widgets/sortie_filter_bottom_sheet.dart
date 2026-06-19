import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_text_field.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import '../../domain/models/bon_sortie.dart';

class SortieFilterBottomSheet extends StatefulWidget {
  final BonSortieFilter currentFilter;
  final ValueChanged<BonSortieFilter> onApply;

  const SortieFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<SortieFilterBottomSheet> createState() => _SortieFilterBottomSheetState();
}

class _SortieFilterBottomSheetState extends State<SortieFilterBottomSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _tierController = TextEditingController();
  final _repController = TextEditingController();
  final _statusController = TextEditingController();
  bool _allDocuments = false;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.currentFilter.dateFrom;
    _dateTo = widget.currentFilter.dateTo;
    _tierController.text = widget.currentFilter.tier ?? '';
    _repController.text = widget.currentFilter.representative ?? '';
    _statusController.text = widget.currentFilter.status ?? '';
    _allDocuments = widget.currentFilter.allDocuments;
  }

  @override
  void dispose() {
    _tierController.dispose();
    _repController.dispose();
    _statusController.dispose();
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
                        ? '${DateFormat('dd/MM/yy').format(_dateFrom!)} - ${DateFormat('dd/MM/yy').format(_dateTo!)}'
                        : 'Sélectionner des dates',
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
    final media = MediaQuery.of(context);

    // List of predefined quick statuses
    final quickStatuses = ['En attente', 'En cours', 'Sorti'];

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: media.viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppBorderRadius.roundedFull,
                ),
              ),
            ),
            AppSpacing.gapL,

            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrer les Bons de Sortie',
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
                      _tierController.clear();
                      _repController.clear();
                      _statusController.clear();
                      _allDocuments = false;
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AppSpacing.gapL,

            // Date Range Selection
            _buildDatePickerCard(theme),
            AppSpacing.gapL,

            // Customer Filter Input
            AppTextField(
              controller: _tierController,
              labelText: 'Client (Code/ID)',
              hintText: 'Ex: 11',
              prefixIcon: Icons.person_outline_rounded,
            ),
            AppSpacing.gapL,

            // Representative Filter Input
            AppTextField(
              controller: _repController,
              labelText: 'Représentant',
              hintText: 'Ex: 11249',
              prefixIcon: Icons.badge_outlined,
            ),
            AppSpacing.gapL,

            // Status Filter Input
            AppTextField(
              controller: _statusController,
              labelText: 'Statut / Etat',
              hintText: 'Ex: Sorti',
              prefixIcon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 8),

            // Quick Status Chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: quickStatuses.map((status) {
                final isSelected = _statusController.text.trim().toLowerCase() == status.toLowerCase();
                return ChoiceChip(
                  label: Text(
                    status,
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
                      _statusController.text = selected ? status : '';
                    });
                  },
                );
              }).toList(),
            ),
            AppSpacing.gapL,

            // All Documents Toggle Switch Card
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
                  'Afficher toutes les pièces',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Inclure les types et classes complémentaires',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: _allDocuments,
                onChanged: (val) {
                  setState(() {
                    _allDocuments = val;
                  });
                },
              ),
            ),
            AppSpacing.gapXl,

            // Apply Filters Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: 'Appliquer les filtres',
                onPressed: () {
                  final newFilter = BonSortieFilter(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    tier: _tierController.text.trim(),
                    representative: _repController.text.trim(),
                    status: _statusController.text.trim(),
                    allDocuments: _allDocuments,
                    advancedFilterActive: _dateFrom != null ||
                        _tierController.text.isNotEmpty ||
                        _repController.text.isNotEmpty ||
                        _statusController.text.isNotEmpty ||
                        _allDocuments,
                  );
                  widget.onApply(newFilter);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
