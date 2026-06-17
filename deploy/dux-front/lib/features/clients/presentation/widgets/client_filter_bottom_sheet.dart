import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../domain/models/client_filter.dart';
import '../controllers/clients_controller.dart';

class ClientFilterBottomSheet extends ConsumerStatefulWidget {
  const ClientFilterBottomSheet({super.key});

  @override
  ConsumerState<ClientFilterBottomSheet> createState() => _ClientFilterBottomSheetState();
}

class _ClientFilterBottomSheetState extends ConsumerState<ClientFilterBottomSheet> {
  late TextEditingController _searchController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(clientsControllerProvider).filter;
    _searchController = TextEditingController(text: currentFilter.searchTerm);
    _startDate = currentFilter.startDate;
    _endDate = currentFilter.endDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final newFilter = ClientFilter(
      searchTerm: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
    ref.read(clientsControllerProvider.notifier).updateFilter(newFilter);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Filtrer les Clients',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapL,
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Recherche par nom ou code',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          AppSpacing.gapL,
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_startDate == null ? 'Date début' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                ),
              ),
              AppSpacing.gapM,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_endDate == null ? 'Date fin' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                ),
              ),
            ],
          ),
          AppSpacing.gapXxl,
          
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Réinitialiser'),
                ),
              ),
              AppSpacing.gapM,
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
          AppSpacing.gapL,
        ],
      ),
    );
  }
}
