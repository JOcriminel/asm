import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../models/screen_config.dart';
import '../models/category.dart';
import '../network/dio_client.dart';

class ScreenConfigState {
  final Map<String, ScreenConfig> configs;
  final List<Category> categories;
  final bool isLoading;

  const ScreenConfigState({
    required this.configs,
    required this.categories,
    this.isLoading = false,
  });

  ScreenConfigState copyWith({
    Map<String, ScreenConfig>? configs,
    List<Category>? categories,
    bool? isLoading,
  }) {
    return ScreenConfigState(
      configs: configs ?? this.configs,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ScreenConfigController extends StateNotifier<ScreenConfigState> {
  final StorageService _storageService;
  final Dio _dio;

  ScreenConfigController(this._storageService, this._dio)
      : super(const ScreenConfigState(configs: {}, categories: [], isLoading: true)) {
    _loadConfigs();
  }

  static const String _storageKey = 'dux_screen_configs';
  static const String _categoriesKey = 'dux_categories';

  static Map<String, ScreenConfig> get _defaultConfigs => {
        'BC': const ScreenConfig(
          documentType: 'BC',
          pageTitle: 'Bon de Commande',
          searchHint: 'Search code, customer or representative...',
          enableBarcodeScanner: false,
          enablePdfPrinting: true,
          enableSerialNumberTracking: false,
          enableChecklistTracking: false,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BC-D',
          hidePricesForOperateurs: false,
          hidePrices: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#2196F3',
          requireSignature: false,
          requirePhoto: false,
          defaultSortField: 'date',
          enableSoundAlerts: true,
          enableVibrationAlerts: true,
          isActive: true,
          category: 'Gestion de Vente',
        ),
        'BP': const ScreenConfig(
          documentType: 'BP',
          pageTitle: 'Bon de Préparation',
          searchHint: 'Search code, customer or representative...',
          enableBarcodeScanner: true,
          enablePdfPrinting: false,
          enableSerialNumberTracking: true,
          enableChecklistTracking: true,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BP-D',
          hidePricesForOperateurs: false,
          hidePrices: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#4CAF50',
          requireSignature: false,
          requirePhoto: true,
          defaultSortField: 'status',
          enableSoundAlerts: true,
          enableVibrationAlerts: true,
          isActive: true,
          category: 'Gestion de Vente',
        ),
        'BPR': const ScreenConfig(
          documentType: 'BPR',
          pageTitle: 'Bon de Réservation',
          searchHint: 'Search code, customer or representative...',
          enableBarcodeScanner: false,
          enablePdfPrinting: true,
          enableSerialNumberTracking: false,
          enableChecklistTracking: false,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BPR-D',
          hidePricesForOperateurs: false,
          hidePrices: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#9C27B0',
          requireSignature: false,
          requirePhoto: false,
          defaultSortField: 'date',
          enableSoundAlerts: true,
          enableVibrationAlerts: true,
          isActive: true,
          category: 'Gestion de Vente',
        ),
        'BS': const ScreenConfig(
          documentType: 'BS',
          pageTitle: 'Bon de Sortie',
          searchHint: 'Rechercher code, client ou représentant...',
          enableBarcodeScanner: false,
          enablePdfPrinting: false,
          enableSerialNumberTracking: false,
          enableChecklistTracking: false,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BS-D',
          hidePricesForOperateurs: false,
          hidePrices: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#FF9800',
          requireSignature: true,
          requirePhoto: false,
          defaultSortField: 'date',
          enableSoundAlerts: true,
          enableVibrationAlerts: true,
          isActive: true,
          category: 'Gestion de Vente',
        ),
      };

  static List<Category> get _defaultCategories =>
      [Category(name: 'Gestion de Vente', active: true)];

  static const String _pendingSyncActionsKey = 'dux_screen_configs_pending_sync_actions';

  Future<Map<String, String>> _loadPendingSyncActions() async {
    try {
      final jsonStr = await _storageService.read(_pendingSyncActionsKey);
      if (jsonStr != null) {
        return Map<String, String>.from(jsonDecode(jsonStr) as Map);
      }
    } catch (_) {}
    return {};
  }

  Future<void> _savePendingSyncActions(Map<String, String> actions) async {
    try {
      await _storageService.write(_pendingSyncActionsKey, jsonEncode(actions));
    } catch (_) {}
  }

  Future<void> _syncPendingActions() async {
    final actions = await _loadPendingSyncActions();
    if (actions.isEmpty) return;

    final actionsCopy = Map<String, String>.from(actions);
    
    Map<String, ScreenConfig> currentConfigs = state.configs;
    if (currentConfigs.isEmpty) {
      try {
        final dataStr = await _storageService.read(_storageKey);
        if (dataStr != null) {
          final Map<String, dynamic> decoded = jsonDecode(dataStr);
          currentConfigs = decoded.map((key, val) =>
              MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));
        }
      } catch (_) {}
    }

    for (final entry in actions.entries) {
      final docType = entry.key;
      final action = entry.value;

      try {
        if (action == 'update') {
          final config = currentConfigs[docType];
          if (config != null) {
            await _dio.put('/screen-configs/$docType', data: config.toJson());
          }
        } else if (action == 'delete') {
          await _dio.delete('/screen-configs/$docType');
        }
        actionsCopy.remove(docType);
      } catch (_) {
        // Stop sync on first network error
        break;
      }
    }

    await _savePendingSyncActions(actionsCopy);
  }

  Future<void> _loadConfigs() async {
    // 0. Sync any pending offline actions first
    await _syncPendingActions();

    List<Category> categories = _defaultCategories;

    // 1. Fetch categories
    try {
      final catResponse = await _dio.get('/categories');
      if (catResponse.statusCode == 200 && catResponse.data is List) {
        categories = (catResponse.data as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        // Cache locally
        try {
          await _storageService.write(
              _categoriesKey, jsonEncode(categories.map((c) => c.toJson()).toList()));
        } catch (_) {}
      }
    } catch (_) {
      // offline/error fallback: try loading from local cache
      try {
        final catDataStr = await _storageService.read(_categoriesKey);
        if (catDataStr != null) {
          categories = (jsonDecode(catDataStr) as List)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Fetch configs
    try {
      final response = await _dio.get('/screen-configs');
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> decoded =
            Map<String, dynamic>.from(response.data as Map);
        final configs = decoded.map((key, val) =>
            MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));

        // Merge remaining pending changes on top of server configs
        final pendingActions = await _loadPendingSyncActions();
        if (pendingActions.isNotEmpty) {
          Map<String, ScreenConfig> localConfigs = {};
          try {
            final dataStr = await _storageService.read(_storageKey);
            if (dataStr != null) {
              final Map<String, dynamic> localDecoded = jsonDecode(dataStr);
              localConfigs = localDecoded.map((key, val) =>
                  MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));
            }
          } catch (_) {}

          for (final entry in pendingActions.entries) {
            final docType = entry.key;
            final action = entry.value;
            if (action == 'update') {
              final localConfig = localConfigs[docType];
              if (localConfig != null) {
                configs[docType] = localConfig;
              }
            } else if (action == 'delete') {
              configs.remove(docType);
            }
          }
        }

        state = ScreenConfigState(configs: configs, categories: categories, isLoading: false);

        // Update local storage cache
        try {
          final jsonStr =
              jsonEncode(configs.map((key, val) => MapEntry(key, val.toJson())));
          await _storageService.write(_storageKey, jsonStr);
        } catch (_) {}
        return;
      }
    } catch (_) {
      // Backend is offline/unreachable, fallback to local storage
    }

    // 3. Local storage fallback
    try {
      final dataStr = await _storageService.read(_storageKey);
      if (dataStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(dataStr);
        final configs = decoded.map((key, val) =>
            MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));
        state = ScreenConfigState(configs: configs, categories: categories, isLoading: false);
      } else {
        state = ScreenConfigState(
            configs: _defaultConfigs, categories: categories, isLoading: false);
      }
    } catch (_) {
      state = ScreenConfigState(
          configs: _defaultConfigs, categories: categories, isLoading: false);
    }
  }

  Future<void> updateConfig(String docType, ScreenConfig newConfig) async {
    final updatedConfigs = Map<String, ScreenConfig>.from(state.configs);
    updatedConfigs[docType] = newConfig;

    state = state.copyWith(configs: updatedConfigs);

    // Save locally
    try {
      final jsonStr =
          jsonEncode(updatedConfigs.map((key, val) => MapEntry(key, val.toJson())));
      await _storageService.write(_storageKey, jsonStr);
    } catch (_) {}

    // Track pending action
    final actions = await _loadPendingSyncActions();
    actions[docType] = 'update';
    await _savePendingSyncActions(actions);

    // Sync to backend
    try {
      await _dio.put('/screen-configs/$docType', data: newConfig.toJson());
      // On success, clear from pending actions
      final latestActions = await _loadPendingSyncActions();
      latestActions.remove(docType);
      await _savePendingSyncActions(latestActions);
    } catch (_) {}
  }

  Future<void> deleteConfig(String docType) async {
    final updatedConfigs = Map<String, ScreenConfig>.from(state.configs);
    updatedConfigs.remove(docType);

    state = state.copyWith(configs: updatedConfigs);

    // Save locally
    try {
      final jsonStr =
          jsonEncode(updatedConfigs.map((key, val) => MapEntry(key, val.toJson())));
      await _storageService.write(_storageKey, jsonStr);
    } catch (_) {}

    // Track pending action
    final actions = await _loadPendingSyncActions();
    actions[docType] = 'delete';
    await _savePendingSyncActions(actions);

    // Sync to backend
    try {
      await _dio.delete('/screen-configs/$docType');
      // On success, clear from pending actions
      final latestActions = await _loadPendingSyncActions();
      latestActions.remove(docType);
      await _savePendingSyncActions(latestActions);
    } catch (_) {}
  }

  Future<void> createCategory(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      await _dio.post('/categories', data: {'name': name, 'active': true});
    } catch (_) {}
    await _loadConfigs();
  }

  Future<void> updateCategory(String oldName, Category updated) async {
    // Optimistic UI update
    final updatedList = state.categories.map((c) {
      return c.name == oldName ? updated : c;
    }).toList();
    state = state.copyWith(categories: updatedList);

    // Persist locally
    try {
      await _storageService.write(
          _categoriesKey, jsonEncode(updatedList.map((c) => c.toJson()).toList()));
    } catch (_) {}

    // Sync to backend (PUT /categories/{oldName})
    try {
      await _dio.put('/categories/$oldName', data: updated.toJson());
    } catch (_) {}
  }

  Future<void> deleteCategory(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      await _dio.delete('/categories/$name');
    } catch (_) {}
    await _loadConfigs();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableClasses() async {
    try {
      final response = await _dio.get('/screen-configs/available-classes');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (_) {}
    return [];
  }
}

final screenConfigControllerProvider =
    StateNotifierProvider<ScreenConfigController, ScreenConfigState>((ref) {
  return ScreenConfigController(
    ref.watch(storageServiceProvider),
    ref.watch(dioProvider),
  );
});
