import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/models/category.dart';
import 'package:dux_front/core/models/screen_config.dart';

class CategoriesAdminScreen extends ConsumerStatefulWidget {
  const CategoriesAdminScreen({super.key});

  @override
  ConsumerState<CategoriesAdminScreen> createState() => _CategoriesAdminScreenState();
}

class _CategoriesAdminScreenState extends ConsumerState<CategoriesAdminScreen> {
  final _categoryNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _categoryNameController.text.trim();
    _categoryNameController.clear();
    
    await ref.read(screenConfigControllerProvider.notifier).createCategory(name);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catégorie "$name" créée avec succès'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: category.name);
    bool active = category.active;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final configState = ref.watch(screenConfigControllerProvider);
            
            // Pages currently in this category
            final assignedPages = configState.configs.entries
                .where((entry) => entry.value.category == category.name && entry.value.isActive)
                .toList();

            // Pages not in this category that can be added
            final availablePages = configState.configs.entries
                .where((entry) => entry.value.category != category.name && entry.value.isActive)
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Modifier la catégorie : ${category.name}'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Renaming field
                      TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Nom de la catégorie',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active state switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Catégorie active', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(active ? 'Actif (apparaît dans le menu)' : 'Non (n\'apparaît pas dans le menu)'),
                        value: active,
                        onChanged: (val) {
                          setStateDialog(() {
                            active = val;
                          });
                        },
                      ),
                      const Divider(height: 32),
                      Text(
                        'Pages associées (${assignedPages.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (assignedPages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Aucune page associée. Les pages s\'afficheront sous "Accueil".',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: assignedPages.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final entry = assignedPages[index];
                              return ListTile(
                                dense: true,
                                title: Text('${entry.value.pageTitle} (${entry.key})'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.link_off, color: Colors.redAccent),
                                  tooltip: 'Désassocier',
                                  onPressed: () async {
                                    final updated = entry.value.copyWith(category: '');
                                    await ref.read(screenConfigControllerProvider.notifier).updateConfig(entry.key, updated);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Searchable dropdown to add pages
                      SearchablePageDropdown(
                        pages: availablePages,
                        onChanged: (pageKey) async {
                          final entry = configState.configs[pageKey]!;
                          final updated = entry.copyWith(category: category.name);
                          await ref.read(screenConfigControllerProvider.notifier).updateConfig(pageKey, updated);
                        },
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
                ElevatedButton(
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) return;
                    
                    final updatedCategory = category.copyWith(name: newName, active: active);
                    await ref.read(screenConfigControllerProvider.notifier).updateCategory(category.name, updatedCategory);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Catégorie mise à jour avec succès'),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Gérer les Catégories'),
      ),
      body: configState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Card to Add Category
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajouter une nouvelle catégorie',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.gapL,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                idField(),
                                AppSpacing.gapM,
                                createButton(theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Text(
                    'Catégories existantes (${configState.categories.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapL,
                  Expanded(
                    child: configState.categories.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune catégorie personnalisée définie.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.separated(
                            itemCount: configState.categories.length,
                            separatorBuilder: (context, index) => AppSpacing.gapM,
                            itemBuilder: (context, index) {
                              final category = configState.categories[index];
                              final name = category.name;
                              final isActive = category.active;

                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m,
                                  vertical: AppSpacing.s,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.folder_open_rounded,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.m),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                          tooltip: 'Modifier',
                                          onPressed: () => _showEditCategoryDialog(category),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16, thickness: 0.5),
                                    Row(
                                      children: [
                                        Text(
                                          isActive ? 'Actif (apparaît)' : 'Non (n\'apparaît pas)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isActive ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: isActive,
                                          onChanged: (val) async {
                                            final updated = category.copyWith(active: val);
                                            await ref.read(screenConfigControllerProvider.notifier).updateCategory(name, updated);
                                          },
                                          activeThumbColor: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget idField() {
    return Expanded(
      child: TextFormField(
        controller: _categoryNameController,
        decoration: InputDecoration(
          labelText: 'Nom de la catégorie',
          hintText: 'Ex: Gestion de Vente, Achat, etc.',
          prefixIcon: const Icon(Icons.folder_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'Veuillez saisir un nom';
          }
          return null;
        },
        onFieldSubmitted: (_) => _addCategory(),
      ),
    );
  }

  Widget createButton(ThemeData theme) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _addCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
    );
  }
}

class SearchablePageDropdown extends StatefulWidget {
  final List<MapEntry<String, ScreenConfig>> pages;
  final ValueChanged<String> onChanged;

  const SearchablePageDropdown({
    super.key,
    required this.pages,
    required this.onChanged,
  });

  @override
  State<SearchablePageDropdown> createState() => _SearchablePageDropdownState();
}

class _SearchablePageDropdownState extends State<SearchablePageDropdown> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  List<MapEntry<String, ScreenConfig>> _filteredPages = [];

  @override
  void initState() {
    super.initState();
    _filteredPages = widget.pages;
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
        if (_focusNode.hasFocus) {
          _controller.clear();
          _filteredPages = widget.pages;
        } else {
          _controller.text = '';
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant SearchablePageDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages != oldWidget.pages) {
      _filteredPages = widget.pages;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterPages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPages = widget.pages;
      } else {
        _filteredPages = widget.pages
            .where((entry) =>
                entry.key.toLowerCase().contains(query.toLowerCase()) ||
                entry.value.pageTitle.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Ajouter une page à cette catégorie',
            hintText: 'Rechercher une page...',
            prefixIcon: const Icon(Icons.pageview_outlined),
            suffixIcon: _focusNode.hasFocus
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _focusNode.unfocus();
                    },
                  )
                : const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _filterPages,
        ),
        if (_isExpanded && _filteredPages.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredPages.length,
              itemBuilder: (context, index) {
                final entry = _filteredPages[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${entry.value.pageTitle} (${entry.key})',
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                  onTap: () {
                    widget.onChanged(entry.key);
                    _controller.clear();
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
