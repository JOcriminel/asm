import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/services/user_roles_provider.dart';

class EditScreenConfigScreen extends ConsumerStatefulWidget {
  final String docType;

  const EditScreenConfigScreen({
    super.key,
    required this.docType,
  });

  @override
  ConsumerState<EditScreenConfigScreen> createState() => _EditScreenConfigScreenState();
}

class _EditScreenConfigScreenState extends ConsumerState<EditScreenConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _searchHintController = TextEditingController();
  final _detailTitleController = TextEditingController();

  bool _scanEnabled = false;
  bool _printEnabled = false;
  bool _snEnabled = false;
  bool _hidePrices = false;
  List<String> _selectedRoles = [];
  List<String> _allowedRolesToFinalize = [];

  // New settings
  String _primaryColor = '#2196F3';
  bool _requireSignature = false;
  bool _requirePhoto = false;
  String _defaultSortField = 'date';
  bool _enableSoundAlerts = true;
  bool _enableVibrationAlerts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initValues();
    });
  }

  void _initValues() {
    final state = ref.read(screenConfigControllerProvider);
    final config = state.configs[widget.docType];
    if (config == null) return;

    _titleController.text = config.pageTitle;
    _searchHintController.text = config.searchHint;
    _detailTitleController.text = config.detailPageTitle;
    setState(() {
      _scanEnabled = config.enableBarcodeScanner;
      _printEnabled = config.enablePdfPrinting;
      _snEnabled = config.enableSerialNumberTracking;
      _selectedRoles = List<String>.from(config.visibleRoles);
      _hidePrices = config.hidePricesForOperateurs;
      _allowedRolesToFinalize = List<String>.from(config.allowedRolesToFinalize);
      _primaryColor = config.primaryColor;
      _requireSignature = config.requireSignature;
      _requirePhoto = config.requirePhoto;
      _defaultSortField = config.defaultSortField;
      _enableSoundAlerts = config.enableSoundAlerts;
      _enableVibrationAlerts = config.enableVibrationAlerts;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchHintController.dispose();
    _detailTitleController.dispose();
    super.dispose();
  }

  String _getFriendlyName(String type) {
    switch (type) {
      case 'BC':
        return 'Bon de Commande';
      case 'BP':
        return 'Bon de Préparation';
      case 'BS':
        return 'Bon de Sortie';
      default:
        return 'Document';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(screenConfigControllerProvider);
    final current = state.configs[widget.docType];
    if (current == null) return;

    final updated = current.copyWith(
      pageTitle: _titleController.text.trim(),
      searchHint: _searchHintController.text.trim(),
      enableBarcodeScanner: _scanEnabled,
      enablePdfPrinting: _printEnabled,
      enableSerialNumberTracking: _snEnabled,
      visibleRoles: _selectedRoles,
      detailPageTitle: _detailTitleController.text.trim(),
      hidePricesForOperateurs: _hidePrices,
      allowedRolesToFinalize: _allowedRolesToFinalize,
      primaryColor: _primaryColor,
      requireSignature: _requireSignature,
      requirePhoto: _requirePhoto,
      defaultSortField: _defaultSortField,
      enableSoundAlerts: _enableSoundAlerts,
      enableVibrationAlerts: _enableVibrationAlerts,
    );

    await ref.read(screenConfigControllerProvider.notifier).updateConfig(widget.docType, updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              AppSpacing.gapS,
              Expanded(
                child: Text(
                  'Configuration de ${_getFriendlyName(widget.docType)} enregistrée avec succès',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(screenConfigControllerProvider);
    final rolesAsync = ref.watch(userRolesProvider);

    if (configState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final docName = _getFriendlyName(widget.docType);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurer : $docName'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              // LIVE PREVIEW CARD
              // ============================================
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.l),
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_outlined, color: _parseHexColor(_primaryColor), size: 18),
                        AppSpacing.gapS,
                        Text(
                          'Prévisualisation en Temps Réel',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapL,
                    // Mock App Bar / Header Preview
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: _parseHexColor(_primaryColor),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _parseHexColor(_primaryColor).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          AppSpacing.gapM,
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _titleController,
                              builder: (context, _) {
                                return Text(
                                  _titleController.text.trim().isEmpty ? docName : _titleController.text.trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                            ),
                          ),
                          const Icon(Icons.wifi, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    AppSpacing.gapL,
                    // Mock Action Preview
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _parseHexColor(_primaryColor).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: _parseHexColor(_primaryColor),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapM,
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _parseHexColor(_primaryColor),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _parseHexColor(_primaryColor).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Valider S/N',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildSectionCard(
                title: 'Personnalisation Visuelle',
                icon: Icons.palette_outlined,
                theme: theme,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre de la page',
                      hintText: 'Ex: Bon de Préparation',
                      prefixIcon: const Icon(Icons.title_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre ne peut pas être vide';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapL,
                  TextFormField(
                    controller: _detailTitleController,
                    decoration: InputDecoration(
                      labelText: 'Titre de la page Détails',
                      hintText: 'Ex: BC-D',
                      prefixIcon: const Icon(Icons.display_settings_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre des détails ne peut pas être vide';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapL,
                  TextFormField(
                    controller: _searchHintController,
                    decoration: InputDecoration(
                      labelText: 'Message d\'indication de recherche',
                      hintText: 'Ex: Rechercher code, client...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'indication de recherche ne peut pas être vide';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapL,
                  const Divider(height: 1),
                  AppSpacing.gapL,
                  Text(
                    'Couleur principale de l\'écran',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildColorBubble('#2196F3', Colors.blue, theme),
                      _buildColorBubble('#4CAF50', Colors.green, theme),
                      _buildColorBubble('#FF9800', Colors.orange, theme),
                      _buildColorBubble('#F44336', Colors.red, theme),
                      _buildColorBubble('#9C27B0', Colors.purple, theme),
                      _buildColorBubble('#009688', Colors.teal, theme),
                    ],
                  ),
                  AppSpacing.gapL,
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _defaultSortField,
                    decoration: InputDecoration(
                      labelText: 'Tri par défaut',
                      prefixIcon: const Icon(Icons.sort_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'date', child: Text('Date (Plus récent)')),
                      DropdownMenuItem(value: 'code', child: Text('Code Document')),
                      DropdownMenuItem(value: 'status', child: Text('Statut de Préparation')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _defaultSortField = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Fonctionnalités Actives',
                icon: Icons.toggle_on_outlined,
                theme: theme,
                children: [
                  _buildSwitchItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Lecteur de code-barres',
                    subtitle: 'Affiche l\'icône de scan dans la barre de recherche',
                    value: _scanEnabled,
                    onChanged: (val) => setState(() => _scanEnabled = val),
                    theme: theme,
                  ),
                  _buildSwitchItem(
                    icon: Icons.print_rounded,
                    title: 'Impression PDF',
                    subtitle: 'Affiche le bouton d\'impression de ticket sur les fiches',
                    value: _printEnabled,
                    onChanged: (val) => setState(() => _printEnabled = val),
                    theme: theme,
                  ),
                  _buildSwitchItem(
                    icon: Icons.precision_manufacturing_rounded,
                    title: 'Suivi des numéros de série',
                    subtitle: 'Affiche les détails de scan S/N par article',
                    value: _snEnabled,
                    onChanged: (val) => setState(() => _snEnabled = val),
                    theme: theme,
                  ),
                  _buildSwitchItem(
                    icon: Icons.volume_up_rounded,
                    title: 'Alertes Sonores',
                    subtitle: 'Émet un bip de validation lors du scan d\'un article',
                    value: _enableSoundAlerts,
                    onChanged: (val) => setState(() => _enableSoundAlerts = val),
                    theme: theme,
                  ),
                  _buildSwitchItem(
                    icon: Icons.vibration_rounded,
                    title: 'Vibrations de Retour',
                    subtitle: 'Vibre pour signaler un scan réussi ou une erreur',
                    value: _enableVibrationAlerts,
                    onChanged: (val) => setState(() => _enableVibrationAlerts = val),
                    theme: theme,
                  ),
                  if (widget.docType == 'BC') ...[
                    _buildSwitchItem(
                      icon: Icons.money_off_rounded,
                      title: 'Masquer les prix pour les opérateurs',
                      subtitle: 'Masque les montants financiers (HT, TVA, TTC) sur la liste et les fiches',
                      value: _hidePrices,
                      onChanged: (val) => setState(() => _hidePrices = val),
                      theme: theme,
                    ),
                  ],
                ],
              ),
              _buildSectionCard(
                title: 'Règles de Validation & Clôture',
                icon: Icons.fact_check_outlined,
                theme: theme,
                children: [
                  _buildSwitchItem(
                    icon: Icons.gesture_rounded,
                    title: 'Signature client requise',
                    subtitle: 'Exige la signature du client sur l\'écran avant finalisation',
                    value: _requireSignature,
                    onChanged: (val) => setState(() => _requireSignature = val),
                    theme: theme,
                  ),
                  _buildSwitchItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Photo de preuve requise',
                    subtitle: 'Exige la capture d\'une photo des articles préparés avant validation',
                    value: _requirePhoto,
                    onChanged: (val) => setState(() => _requirePhoto = val),
                    theme: theme,
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Rôles Autorisés',
                icon: Icons.admin_panel_settings_outlined,
                theme: theme,
                children: [
                  Text(
                    'Sélectionnez les rôles des utilisateurs autorisés à voir et utiliser cet écran.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapL,
                  rolesAsync.when(
                    data: (roles) => _MultiSelectDropdown(
                      label: 'Rôles autorisés à voir',
                      items: roles,
                      selectedValues: _selectedRoles,
                      onChanged: (newRoles) {
                        setState(() {
                          _selectedRoles = newRoles;
                        });
                      },
                      theme: theme,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, stack) => const Text('Erreur de chargement des rôles'),
                  ),
                ],
              ),
              if (widget.docType == 'BP') ...[
                _buildSectionCard(
                  title: 'Rôles autorisés à finaliser',
                  icon: Icons.verified_user_outlined,
                  theme: theme,
                  children: [
                    Text(
                      'Sélectionnez les rôles des utilisateurs autorisés à finaliser les préparations de commandes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapL,
                  rolesAsync.when(
                    data: (roles) => _MultiSelectDropdown(
                      label: 'Rôles autorisés à finaliser',
                      items: roles,
                      selectedValues: _allowedRolesToFinalize,
                      onChanged: (newRoles) {
                        setState(() {
                          _allowedRolesToFinalize = newRoles;
                        });
                      },
                      theme: theme,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, stack) => const Text('Erreur de chargement des rôles'),
                  ),
                ],
              ),
            ],
              AppSpacing.gapXl,
              _buildSaveButton(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                AppSpacing.gapM,
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          AppSpacing.gapL,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildColorBubble(String hex, Color color, ThemeData theme) {
    final isSelected = _primaryColor.toLowerCase() == hex.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _primaryColor = hex),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Enregistrer les modifications',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectDropdown extends StatefulWidget {
  final String label;
  final List<UserRole> items;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final ThemeData theme;

  const _MultiSelectDropdown({
    required this.label,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<_MultiSelectDropdown> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _textController = TextEditingController();
  OverlayEntry? _overlayEntry;
  String _searchQuery = '';
  double _width = 300.0;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _textController.text = _getDisplayText();
  }

  @override
  void didUpdateWidget(covariant _MultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      _textController.text = _getDisplayText();
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _textController.clear();
      _searchQuery = '';
      _showOverlay();
    } else {
      _hideOverlay();
      _textController.text = _getDisplayText();
    }
  }

  String _getDisplayText() {
    return widget.selectedValues.isEmpty
        ? 'Aucun rôle sélectionné'
        : widget.items
            .where((item) => widget.selectedValues.contains(item.code))
            .map((item) => item.label)
            .join(', ');
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _width = renderBox.size.width;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final isFinalize = widget.label.toLowerCase().contains('final');

    return OverlayEntry(
      builder: (context) {
        final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? _width;
        final height = renderBox?.size.height ?? 56.0;

        final filteredItems = widget.items.where((item) {
          return item.label.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _focusNode.unfocus();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, height + 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: widget.theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    color: widget.theme.colorScheme.surface,
                    child: Container(
                      width: width,
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                      ),
                      child: filteredItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Aucun rôle trouvé',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Scrollbar(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = widget.selectedValues.contains(item.code);

                                  return SizedBox(
                                    width: width,
                                    child: InkWell(
                                      onTap: () {
                                        final List<String> newSelection = List.from(widget.selectedValues);
                                        if (isSelected) {
                                          newSelection.remove(item.code);
                                        } else {
                                          newSelection.add(item.code);
                                        }
                                        widget.onChanged(newSelection);
                                        _overlayEntry?.markNeedsBuild();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isFinalize ? Icons.verified_user_outlined : Icons.admin_panel_settings_outlined,
                                              size: 20,
                                              color: isSelected
                                                  ? widget.theme.colorScheme.primary
                                                  : widget.theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected
                                                      ? widget.theme.colorScheme.primary
                                                      : widget.theme.colorScheme.onSurface,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            IgnorePointer(
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor: widget.theme.colorScheme.primary,
                                                onChanged: null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinalize = widget.label.toLowerCase().contains('final');

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        key: _key,
        controller: _textController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: _focusNode.hasFocus ? 'Rechercher un rôle...' : null,
          prefixIcon: Icon(
            isFinalize ? Icons.verified_user_outlined : Icons.admin_panel_settings_outlined,
            color: widget.theme.colorScheme.primary,
            size: 20,
          ),
          suffixIcon: Icon(
            _focusNode.hasFocus ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: widget.theme.colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: widget.theme.colorScheme.surface.withValues(alpha: 0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.theme.colorScheme.primary,
              width: 1.8,
            ),
          ),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
          _overlayEntry?.markNeedsBuild();
        },
      ),
    );
  }
}
