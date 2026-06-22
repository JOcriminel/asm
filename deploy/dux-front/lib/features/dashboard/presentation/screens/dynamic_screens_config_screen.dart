import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/models/screen_config.dart';

class DynamicScreensConfigScreen extends ConsumerWidget {
  const DynamicScreensConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);

    if (configState.isLoading) {
      return const DuxLoadingScreen(isFullScreen: true);
    }

    final configs = configState.configs;
    final List<Map<String, dynamic>> menuItems = configs.entries.map((entry) {
      final docType = entry.key;
      final config = entry.value;

      IconData icon;
      if (docType == 'BC') {
        icon = Icons.receipt_long_rounded;
      } else if (docType == 'BP') {
        icon = Icons.inventory_2_outlined;
      } else if (docType == 'BS') {
        icon = Icons.local_shipping_outlined;
      } else if (docType == 'HOME') {
        icon = Icons.home_outlined;
      } else if (docType == 'KPI_DASHBOARD') {
        icon = Icons.dashboard_outlined;
      } else if (docType == 'CLIENTS') {
        icon = Icons.group_outlined;
      } else if (docType == 'ACTIVITY_FEED') {
        icon = Icons.history_outlined;
      } else if (docType == 'STATION') {
        icon = Icons.storefront_outlined;
      } else if (docType == 'PROFILE') {
        icon = Icons.person_outline;
      } else if (docType == 'ADMIN_DASHBOARD') {
        icon = Icons.admin_panel_settings_outlined;
      } else {
        icon = Icons.description_outlined;
      }

      return {
        'title': config.pageTitle,
        'icon': icon,
        'type': docType,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Config Dynamique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Créer un Écran',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _CreateScreenDialog(ref: ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.home_outlined, color: theme.colorScheme.primary),
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.l,
              bottom: AppSpacing.s,
            ),
            child: Text(
              'Sélectionnez l\'écran à configurer :',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.l),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                childAspectRatio: 0.76,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _ConfigMenuCard(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  onTap: () {
                    context.push('/admin/screen-settings/edit/${item['type']}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ConfigMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.gapM,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateScreenDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateScreenDialog({required this.ref});

  @override
  State<_CreateScreenDialog> createState() => _CreateScreenDialogState();
}

class _CreateScreenDialogState extends State<_CreateScreenDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableClasses = [];
  String? _selectedClassCode;
  String _searchQuery = '';
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  Future<void> _loadAvailableClasses() async {
    final classes = await widget.ref
        .read(screenConfigControllerProvider.notifier)
        .fetchAvailableClasses();
    if (mounted) {
      setState(() {
        _availableClasses = classes;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredClasses {
    if (_searchQuery.isEmpty) return _availableClasses;
    final query = _searchQuery.toLowerCase();
    return _availableClasses.where((c) {
      final code = (c['code'] as String).toLowerCase();
      final libelle = (c['libelle'] as String).toLowerCase();
      return code.contains(query) || libelle.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Créer un nouvel écran'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _availableClasses.isEmpty
              ? const Text('Aucune nouvelle classe de document disponible dans DUX.')
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Rechercher une classe (code ou libellé)',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _filteredClasses.isEmpty
                              ? const Center(child: Text('Aucun résultat trouvé'))
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _filteredClasses.map((item) {
                                      final code = item['code'] as String;
                                      final isSelected = _selectedClassCode == code;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        title: Text(
                                          '$code - ${item['libelle']}',
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedClassCode = code;
                                            _titleController.text = item['libelle'] as String;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedClassCode != null) ...[
                          Text(
                            'Classe sélectionnée : $_selectedClassCode',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titre de la page',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Veuillez saisir un titre'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (!_isLoading && _availableClasses.isNotEmpty)
          ElevatedButton(
            onPressed: _selectedClassCode == null
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final code = _selectedClassCode!;
                      final title = _titleController.text.trim();

                      final newConfig = ScreenConfig(
                        documentType: code,
                        pageTitle: title,
                        searchHint: 'Rechercher par code, client...',
                        enableBarcodeScanner: false,
                        enablePdfPrinting: false,
                        enableSerialNumberTracking: false,
                        enableChecklistTracking: false,
                        visibleRoles: const ['admin', 'commercial', 'operateur'],
                        detailPageTitle: '$code-D',
                        hidePricesForOperateurs: false,
                        hidePrices: false,
                        allowedRolesToFinalize: const ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
                        primaryColor: '#2196F3',
                        requireSignature: false,
                        requirePhoto: false,
                        defaultSortField: 'date',
                        enableSoundAlerts: true,
                        enableVibrationAlerts: true,
                        isActive: true,
                      );

                      final navigator = Navigator.of(context);
                      final router = GoRouter.of(context);

                      await widget.ref
                          .read(screenConfigControllerProvider.notifier)
                          .updateConfig(code, newConfig);

                      if (mounted) {
                        navigator.pop();
                        router.push('/admin/screen-settings/edit/$code');
                      }
                    }
                  },
            child: const Text('Créer & Configurer'),
          ),
      ],
    );
  }
}
