import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/app_text_field.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import '../../domain/models/bon_preparation.dart';

class PreparationFilterBottomSheet extends StatefulWidget {
  final BonPreparationFilter currentFilter;
  final ValueChanged<BonPreparationFilter> onApply;

  const PreparationFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<PreparationFilterBottomSheet> createState() => _PreparationFilterBottomSheetState();
}

class _PreparationFilterBottomSheetState extends State<PreparationFilterBottomSheet> {
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
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: media.viewInsets.bottom + AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: AppBorderRadius.roundedFull,
                ),
              ),
            ),
            AppSpacing.gapL,
            Text(
              'Filtrer les Bons',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapL,

            // Date Range Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Période', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)),
                      AppSpacing.gapS,
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded),
                        label: Text(
                          _dateFrom != null && _dateTo != null
                              ? '${DateFormat('dd/MM/yy').format(_dateFrom!)} - ${DateFormat('dd/MM/yy').format(_dateTo!)}'
                              : 'Sélectionner des dates',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _selectDateRange(context),
                      ),
                    ],
                  ),
                ),
                if (_dateFrom != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                      });
                    },
                  ),
              ],
            ),
            AppSpacing.gapM,

            // Customer (Tier) Filter Input
            AppTextField(
              controller: _tierController,
              labelText: 'Client (Code/ID)',
              hintText: 'e.g. 11',
              prefixIcon: Icons.person_outline_rounded,
            ),
            AppSpacing.gapM,

            // Representative Filter Input
            AppTextField(
              controller: _repController,
              labelText: 'Représentant',
              hintText: 'e.g. 11249',
              prefixIcon: Icons.badge_outlined,
            ),
            AppSpacing.gapM,

            // Status Filter Input
            AppTextField(
              controller: _statusController,
              labelText: 'Statut / Etat',
              hintText: 'e.g. Préparé',
              prefixIcon: Icons.info_outline_rounded,
            ),
            AppSpacing.gapM,

            // All Documents toggle switch
            SwitchListTile(
              title: const Text('Afficher toutes les pièces'),
              subtitle: const Text('Inclure les types et classes complémentaires'),
              value: _allDocuments,
              onChanged: (val) {
                setState(() {
                  _allDocuments = val;
                });
              },
            ),
            AppSpacing.gapL,

            // Apply Filters Action
            PrimaryButton(
              text: 'Appliquer les filtres',
              onPressed: () {
                final newFilter = BonPreparationFilter(
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
          ],
        ),
      ),
    );
  }
}
