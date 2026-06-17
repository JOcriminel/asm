import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../../domain/models/bon_preparation.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';

class PreparationChecklistScreen extends ConsumerStatefulWidget {
  final String preparationId;

  const PreparationChecklistScreen({
    super.key,
    required this.preparationId,
  });

  @override
  ConsumerState<PreparationChecklistScreen> createState() => _PreparationChecklistScreenState();
}

class _PreparationChecklistScreenState extends ConsumerState<PreparationChecklistScreen> with SingleTickerProviderStateMixin {
  final Map<String, Map<String, bool>> _installationsByFamily = {};
  final Map<String, Map<String, bool>> _testsByFamily = {};
  
  bool _initialized = false;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeChecklists(BonPreparation preparation) {
    if (_initialized) return;
    
    for (var article in preparation.articles) {
      final code = article.code.trim();
      final family = (article.familyId?.trim() ?? code).toLowerCase();
      final name = article.name.toLowerCase();
      
      // 1. Caisse
      if (['746', '745', '704'].contains(family) || name.contains('caisse')) {
        _addFamilyItems('Caisse', 
          installations: ['Installation Windows', 'Installation pilotes', 'Installation base de données', 'Installation logiciel'],
          tests: ['Test logiciel']
        );
      }
      // 2. Tiroir
      else if (['702'].contains(family) || name.contains('tiroir')) {
        _addFamilyItems('Tiroir', installations: ['Installation Tiroir'], tests: ['Test Tiroir']);
      }
      // 3. Imprimante
      else if (['121', '040', '755', '754', '706', '705'].contains(family) || name.contains('imprimant')) {
        _addFamilyItems('Imprimante', installations: ['Installation Imprimante'], tests: ['Test Impression']);
      }
      // 4. Balance
      else if (['030', '703'].contains(family) || name.contains('balance')) {
        _addFamilyItems('Balance', installations: ['Installation Balance'], tests: ['Test Balance']);
      }
      // 5. Douchette
      else if (['701'].contains(family) || name.contains('douchette')) {
        _addFamilyItems('Douchette', installations: ['Installation Douchette'], tests: ['Test Douchette']);
      }
      // 6. Scanner
      else if (['fam174', '710'].contains(family) || name.contains('scanner')) {
        _addFamilyItems('Scanner', installations: ['Installation Scanner'], tests: ['Test Scanner']);
      }
    }

    if (_installationsByFamily.isEmpty && _testsByFamily.isEmpty) {
      _addFamilyItems('Général', 
        installations: ['Appareil préparé', 'Accessoires inclus', 'Configuration terminée'],
        tests: ["Appareil s'allume", 'Réseau opérationnel', 'Logiciel activé']
      );
    }

    _initialized = true;
  }

  void _addFamilyItems(String familyName, {required List<String> installations, required List<String> tests}) {
    if (!_installationsByFamily.containsKey(familyName)) {
      _installationsByFamily[familyName] = {};
    }
    if (!_testsByFamily.containsKey(familyName)) {
      _testsByFamily[familyName] = {};
    }
    
    for (var item in installations) {
      if (!_installationsByFamily[familyName]!.containsKey(item)) {
        _installationsByFamily[familyName]![item] = false;
      }
    }
    for (var item in tests) {
      if (!_testsByFamily[familyName]!.containsKey(item)) {
        _testsByFamily[familyName]![item] = false;
      }
    }
  }

  bool get _isAllChecked {
    final allInstalls = _installationsByFamily.values.every((f) => f.values.every((v) => v));
    final allTests = _testsByFamily.values.every((f) => f.values.every((v) => v));
    return allInstalls && allTests;
  }

  Future<void> _submitChecklist(BonPreparation preparation) async {
    if (!_isAllChecked || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(bonPreparationRepositoryProvider);
      
      // The status '12' represents 'validée' in DUX ERP
      await repository.updateDocumentStatus(preparation.id, '12', {});

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              AppSpacing.gapS,
              const Expanded(child: Text('Préparation finalisée et validée avec succès!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      ref.read(bonPreparationDetailControllerProvider(preparation.id).notifier).fetchDetails();
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAccordionList(Map<String, Map<String, bool>> familiesMap) {
    final theme = Theme.of(context);
    if (familiesMap.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text('Aucune tâche', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: familiesMap.keys.length,
      separatorBuilder: (context, index) => AppSpacing.gapL,
      itemBuilder: (context, index) {
        final familyName = familiesMap.keys.elementAt(index);
        final items = familiesMap[familyName]!;
        if (items.isEmpty) return const SizedBox.shrink();

        final total = items.length;
        final checked = items.values.where((v) => v).length;
        final isComplete = checked == total;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.roundedM,
            side: BorderSide(
              color: isComplete ? Colors.green.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
            )
          ),
          child: ExpansionTile(
            initiallyExpanded: !isComplete,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              familyName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.green : theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '$checked/$total cochés',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isComplete ? Colors.green : theme.colorScheme.secondary,
              ),
            ),
            trailing: isComplete 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
            children: items.keys.map((item) {
              return CheckboxListTile(
                title: Text(item, style: const TextStyle(fontWeight: FontWeight.w500)),
                value: items[item],
                activeColor: theme.colorScheme.primary,
                onChanged: (bool? value) {
                  setState(() {
                    items[item] = value ?? false;
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonPreparationDetailControllerProvider(widget.preparationId));
    final theme = Theme.of(context);

    if (state.isLoading || state.preparation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final preparation = state.preparation!;
    _initializeChecklists(preparation);

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Checklist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Installations'),
            Tab(icon: Icon(Icons.science), text: 'Tests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccordionList(_installationsByFamily),
          _buildAccordionList(_testsByFamily),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
              backgroundColor: _isAllChecked ? Colors.green : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
            ),
            onPressed: _isAllChecked ? () => _submitChecklist(preparation) : null,
            child: _isSaving 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'READY FOR DELIVERY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
      ),
    );
  }
}
