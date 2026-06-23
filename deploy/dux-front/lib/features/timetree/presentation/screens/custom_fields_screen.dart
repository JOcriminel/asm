import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_custom_fields_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/widgets/dynamic_event_form_renderer.dart';

class TimetreeCustomFieldsScreen extends ConsumerStatefulWidget {
  const TimetreeCustomFieldsScreen({super.key});

  @override
  ConsumerState<TimetreeCustomFieldsScreen> createState() => _TimetreeCustomFieldsScreenState();
}

class _TimetreeCustomFieldsScreenState extends ConsumerState<TimetreeCustomFieldsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Scope filters
  String _selectedScopeType = 'GLOBAL';
  String? _selectedScopeId;

  // Simulator state
  Map<String, String> _simulatorValues = {};
  final GlobalKey<FormState> _simulatorFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load default fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetreeCustomFieldsProvider.notifier).loadFields(
            scopeType: _selectedScopeType,
            scopeId: _selectedScopeId,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onScopeChanged() {
    _simulatorValues.clear();
    ref.read(timetreeCustomFieldsProvider.notifier).loadFields(
          scopeType: _selectedScopeType,
          scopeId: _selectedScopeId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.user?.role.toUpperCase() ?? 'MEMBER';
    final isAdmin = role == 'ADMIN';
    final isChef = role == 'CHEF';

    // Access control: Members are blocked
    if (role == 'MEMBER') {
      return Scaffold(
        drawer: const DuxDrawer(),
        appBar: AppBar(title: const Text('TimeTree – Champs Personnalisés')),
        body: const _RestrictedAccessMessage(),
      );
    }

    final groupsAsync = ref.watch(timetreeGroupsProvider);
    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final fieldsAsync = ref.watch(filteredTimetreeCustomFieldsProvider);
    final theme = Theme.of(context);

    // Filter lists
    final List<TimetreeGroup> groups = groupsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final List<TimetreeCalendar> calendars = calendarsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    // If Chef, restrict scope selection to GROUPS they manage, or GLOBAL read-only (we enforce CRUD block inside hasPermission)
    final List<TimetreeGroup> managedGroups = isChef
        ? groups.where((g) => g.chef?.username == authState.user?.username).toList()
        : groups;

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('TimeTree – Champs Personnalisés'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings_outlined), text: 'Définitions'),
            Tab(icon: Icon(Icons.preview_outlined), text: 'Simulateur Formulaire'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Scope selection header
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Portée du champ',
                        border: InputBorder.none,
                      ),
                      value: _selectedScopeType,
                      items: [
                        const DropdownMenuItem(value: 'GLOBAL', child: Text('Global (Tous)')),
                        const DropdownMenuItem(value: 'GROUP', child: Text('Groupe spécifique')),
                        const DropdownMenuItem(value: 'CALENDAR', child: Text('Agenda spécifique')),
                        const DropdownMenuItem(value: 'EVENT', child: Text('Événement spécifique')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedScopeType = val;
                            _selectedScopeId = null;
                          });
                          _onScopeChanged();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedScopeType == 'GROUP')
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner Groupe',
                          border: InputBorder.none,
                        ),
                        value: _selectedScopeId,
                        items: managedGroups.map((g) {
                          return DropdownMenuItem(value: g.id, child: Text(g.name));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedScopeId = val;
                          });
                          _onScopeChanged();
                        },
                      ),
                    )
                  else if (_selectedScopeType == 'CALENDAR')
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner Agenda',
                          border: InputBorder.none,
                        ),
                        value: _selectedScopeId,
                        items: calendars.map((c) {
                          return DropdownMenuItem(value: c.id, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedScopeId = val;
                          });
                          _onScopeChanged();
                        },
                      ),
                    )
                  else if (_selectedScopeType == 'EVENT')
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'ID Événement',
                          hintText: 'ex: 45',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedScopeId = val.trim().isEmpty ? null : val;
                          });
                          _onScopeChanged();
                        },
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Management View
                _buildManagementTab(context, fieldsAsync, theme, isAdmin, isChef, managedGroups),

                // Tab 2: Simulator View
                _buildSimulatorTab(context, fieldsAsync, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTab(
    BuildContext context,
    AsyncValue<List<TimetreeCustomField>> fieldsAsync,
    ThemeData theme,
    bool isAdmin,
    bool isChef,
    List<TimetreeGroup> managedGroups,
  ) {
    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Erreur: $err', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () => ref.read(timetreeCustomFieldsProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun champ personnalisé configuré pour cette portée.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Créer un champ'),
              onPressed: () => _showFieldFormDialog(context, managedGroups: managedGroups),
            ),
          );
        }

        // Check if Chef can write for the current scope
        bool canWrite = isAdmin;
        if (isChef) {
          if (_selectedScopeType == 'GROUP' && _selectedScopeId != null) {
            canWrite = managedGroups.any((g) => g.id == _selectedScopeId);
          }
        }

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          ref.read(timetreeCustomFieldSearchQueryProvider.notifier).state = val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un champ…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (canWrite) ...[
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Faites glisser les poignées pour réordonner',
                        child: Icon(Icons.info_outline_rounded, size: 20),
                      ),
                    ]
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  onReorder: (oldIndex, newIndex) {
                    if (canWrite) {
                      ref.read(timetreeCustomFieldsProvider.notifier).reorderFields(oldIndex, newIndex);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permission insuffisante pour réordonner')),
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final field = list[index];
                    return Card(
                      key: ValueKey(field.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: canWrite
                            ? const Icon(Icons.drag_handle_rounded)
                            : const Icon(Icons.lock_outline_rounded, size: 16),
                        title: Text('${field.label} (${field.name})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${field.fieldType} • Portée: ${field.scopeType} ${field.scopeId ?? "Globale"}'),
                            if (field.required)
                              Text('Requis', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              field.active ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                color: field.active ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (canWrite) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showFieldFormDialog(context, field: field, managedGroups: managedGroups),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteField(context, field),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: canWrite
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un champ'),
                  onPressed: () => _showFieldFormDialog(context, managedGroups: managedGroups),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSimulatorTab(
    BuildContext context,
    AsyncValue<List<TimetreeCustomField>> fieldsAsync,
    ThemeData theme,
  ) {
    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const Center(child: Text('Erreur lors du chargement')),
      data: (list) {
        final activeFields = list.where((f) => f.active).toList();
        if (activeFields.isEmpty) {
          return const Center(child: Text('Aucun champ actif pour prévisualiser.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aperçu du formulaire d\'événement',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ce simulateur génère dynamiquement les widgets d\'entrée correspondants et exécute les règles de validation.',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 32),
              
              DynamicEventFormRenderer(
                fields: activeFields,
                values: _simulatorValues,
                formKey: _simulatorFormKey,
                onValuesChanged: (updated) {
                  setState(() {
                    _simulatorValues = updated;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _simulatorValues.clear();
                      });
                      _simulatorFormKey.currentState?.reset();
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      if (_simulatorFormKey.currentState?.validate() ?? false) {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Validation réussie !'),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Valeurs capturées :'),
                                  const SizedBox(height: 12),
                                  ..._simulatorValues.entries.map((e) {
                                    final field = activeFields.firstWhere((f) => f.id == e.key);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text('• ${field.label} (${field.name}): "${e.value}"'),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('Soumettre & Valider'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFieldFormDialog(BuildContext context, {TimetreeCustomField? field, required List<TimetreeGroup> managedGroups}) {
    showDialog<void>(
      context: context,
      builder: (context) => _FieldFormDialog(
        field: field,
        defaultScopeType: _selectedScopeType,
        defaultScopeId: _selectedScopeId,
        managedGroups: managedGroups,
      ),
    );
  }

  void _confirmDeleteField(BuildContext context, TimetreeCustomField field) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le champ ?'),
        content: Text('Voulez-vous vraiment supprimer définitivement le champ "${field.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(timetreeCustomFieldsProvider.notifier).deleteField(field.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Champ supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Fields CRUD Dialog Form
// ─────────────────────────────────────────────────────────────────────────────
class _FieldFormDialog extends ConsumerStatefulWidget {
  final TimetreeCustomField? field;
  final String defaultScopeType;
  final String? defaultScopeId;
  final List<TimetreeGroup> managedGroups;

  const _FieldFormDialog({
    this.field,
    required this.defaultScopeType,
    this.defaultScopeId,
    required this.managedGroups,
  });

  @override
  ConsumerState<_FieldFormDialog> createState() => _FieldFormDialogState();
}

class _FieldFormDialogState extends ConsumerState<_FieldFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _label;
  late String _fieldType;
  late bool _required;
  String? _defaultValue;
  String? _options;
  late String _scopeType;
  String? _scopeId;
  late bool _active;

  // Validation settings
  double? _minValue;
  double? _maxValue;
  int? _minLength;
  int? _maxLength;
  String? _regexPattern;

  // Display rules
  late bool _hidden;
  late bool _readOnly;
  String? _visibilityRule;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _name = f?.name ?? '';
    _label = f?.label ?? '';
    _fieldType = f?.fieldType ?? 'STRING';
    _required = f?.required ?? false;
    _defaultValue = f?.defaultValue;
    _options = f?.options;
    _scopeType = f?.scopeType ?? widget.defaultScopeType;
    _scopeId = f?.scopeId ?? widget.defaultScopeId;
    _active = f?.active ?? true;

    _minValue = f?.minValue;
    _maxValue = f?.maxValue;
    _minLength = f?.minLength;
    _maxLength = f?.maxLength;
    _regexPattern = f?.regexPattern;

    _hidden = f?.hidden ?? false;
    _readOnly = f?.readOnly ?? false;
    _visibilityRule = f?.visibilityRule;
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final calendars = calendarsAsync.maybeWhen(data: (list) => list, orElse: () => <TimetreeCalendar>[]);

    final isEdit = widget.field != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier le champ' : 'Créer un champ'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Identifiant (ex: telephone)'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Requis' : null,
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _label,
                  decoration: const InputDecoration(labelText: 'Libellé affiché (ex: Numéro de téléphone)'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Requis' : null,
                  onSaved: (val) => _label = val!.trim(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type de champ'),
                  value: _fieldType,
                  items: [
                    'STRING', 'TEXT_AREA', 'INTEGER', 'FLOAT', 'BOOLEAN', 
                    'DATE', 'DATETIME', 'EMAIL', 'PHONE', 'URL', 
                    'RADIO', 'CHECKBOX', 'DROPDOWN', 'MULTI_SELECT'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _fieldType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Options listing for select types
                if (['RADIO', 'CHECKBOX', 'DROPDOWN', 'MULTI_SELECT'].contains(_fieldType)) ...[
                  TextFormField(
                    initialValue: _options,
                    decoration: const InputDecoration(
                      labelText: 'Options possibles (séparées par des virgules)',
                      hintText: 'Option A, Option B, Option C',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Veuillez saisir au moins une option' : null,
                    onSaved: (val) => _options = val,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  initialValue: _defaultValue,
                  decoration: const InputDecoration(labelText: 'Valeur par défaut (facultative)'),
                  onSaved: (val) => _defaultValue = val?.trim().isEmpty == true ? null : val?.trim(),
                ),
                const SizedBox(height: 12),
                // Portée select
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Portée'),
                  value: _scopeType,
                  items: ['GLOBAL', 'GROUP', 'CALENDAR', 'EVENT']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _scopeType = val;
                        _scopeId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (_scopeType == 'GROUP')
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Groupe cible'),
                    value: _scopeId,
                    items: widget.managedGroups.map((g) {
                      return DropdownMenuItem(value: g.id, child: Text(g.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _scopeId = val),
                    validator: (val) => val == null ? 'Sélectionnez un groupe' : null,
                  )
                else if (_scopeType == 'CALENDAR')
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Agenda cible'),
                    value: _scopeId,
                    items: calendars.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _scopeId = val),
                    validator: (val) => val == null ? 'Sélectionnez un agenda' : null,
                  )
                else if (_scopeType == 'EVENT')
                  TextFormField(
                    initialValue: _scopeId,
                    decoration: const InputDecoration(labelText: 'ID Événement cible'),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'ID requis' : null,
                    onSaved: (val) => _scopeId = val!.trim(),
                  ),
                
                const Divider(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Validation & Limites', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minValue?.toString(),
                        decoration: const InputDecoration(labelText: 'Min valeur'),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _minValue = val != null ? double.tryParse(val) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _maxValue?.toString(),
                        decoration: const InputDecoration(labelText: 'Max valeur'),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _maxValue = val != null ? double.tryParse(val) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minLength?.toString(),
                        decoration: const InputDecoration(labelText: 'Longueur min'),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _minLength = val != null ? int.tryParse(val) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _maxLength?.toString(),
                        decoration: const InputDecoration(labelText: 'Longueur max'),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _maxLength = val != null ? int.tryParse(val) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _regexPattern,
                  decoration: const InputDecoration(labelText: 'Expression régulière (regex)'),
                  onSaved: (val) => _regexPattern = val?.trim().isEmpty == true ? null : val?.trim(),
                ),
                
                const Divider(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Règles d\'affichage', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _visibilityRule,
                  decoration: const InputDecoration(
                    labelText: 'Visibilité conditionnelle',
                    hintText: 'FieldName == valeur',
                  ),
                  onSaved: (val) => _visibilityRule = val?.trim().isEmpty == true ? null : val?.trim(),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Champ masqué (caché)'),
                  value: _hidden,
                  onChanged: (val) => setState(() => _hidden = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Lecture seule (bloqué)'),
                  value: _readOnly,
                  onChanged: (val) => setState(() => _readOnly = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Champ obligatoire (requis)'),
                  value: _required,
                  onChanged: (val) => setState(() => _required = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Champ actif'),
                  value: _active,
                  onChanged: (val) => setState(() => _active = val ?? false),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final notifier = ref.read(timetreeCustomFieldsProvider.notifier);

      final newField = TimetreeCustomField(
        id: widget.field?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        label: _label,
        fieldType: _fieldType,
        required: _required,
        defaultValue: _defaultValue,
        options: _options,
        scopeType: _scopeType,
        scopeId: _scopeId,
        sortOrder: widget.field?.sortOrder ?? 0,
        active: _active,
        minValue: _minValue,
        maxValue: _maxValue,
        minLength: _minLength,
        maxLength: _maxLength,
        regexPattern: _regexPattern,
        hidden: _hidden,
        readOnly: _readOnly,
        visibilityRule: _visibilityRule,
      );

      try {
        if (widget.field != null) {
          await notifier.updateField(newField);
        } else {
          await notifier.createField(newField);
        }
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.field != null ? 'Champ modifié avec succès' : 'Champ créé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

// Restricted Access Message Widget
class _RestrictedAccessMessage extends StatelessWidget {
  const _RestrictedAccessMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Accès Restreint',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seuls les administrateurs et les chefs d\'équipe peuvent gérer les définitions de champs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
