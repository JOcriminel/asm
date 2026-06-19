import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../models/screen_config.dart';
import '../network/dio_client.dart';

class ScreenConfigState {
  final Map<String, ScreenConfig> configs;
  final bool isLoading;

  const ScreenConfigState({
    required this.configs,
    this.isLoading = false,
  });

  ScreenConfigState copyWith({
    Map<String, ScreenConfig>? configs,
    bool? isLoading,
  }) {
    return ScreenConfigState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ScreenConfigController extends StateNotifier<ScreenConfigState> {
  final StorageService _storageService;
  final Dio _dio;

  ScreenConfigController(this._storageService, this._dio)
      : super(const ScreenConfigState(configs: {}, isLoading: true)) {
    _loadConfigs();
  }

  static const String _storageKey = 'dux_screen_configs';

  static Map<String, ScreenConfig> get _defaultConfigs => {
        'BC': const ScreenConfig(
          documentType: 'BC',
          pageTitle: 'Bon de Commande',
          searchHint: 'Search code, customer or representative...',
          enableBarcodeScanner: false,
          enablePdfPrinting: true,
          enableSerialNumberTracking: false,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BC-D',
          hidePricesForOperateurs: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#2196F3', // Blue
          requireSignature: false,
          requirePhoto: false,
          defaultSortField: 'date',
        ),
        'BP': const ScreenConfig(
          documentType: 'BP',
          pageTitle: 'Bon de Préparation',
          searchHint: 'Search code, customer or representative...',
          enableBarcodeScanner: true,
          enablePdfPrinting: false,
          enableSerialNumberTracking: true,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BP-D',
          hidePricesForOperateurs: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#4CAF50', // Green
          requireSignature: false,
          requirePhoto: true,
          defaultSortField: 'status',
        ),
        'BS': const ScreenConfig(
          documentType: 'BS',
          pageTitle: 'Bon de Sortie',
          searchHint: 'Rechercher code, client ou représentant...',
          enableBarcodeScanner: false,
          enablePdfPrinting: false,
          enableSerialNumberTracking: false,
          visibleRoles: ['admin', 'commercial', 'operateur'],
          detailPageTitle: 'BS-D',
          hidePricesForOperateurs: false,
          allowedRolesToFinalize: ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
          primaryColor: '#FF9800', // Orange
          requireSignature: true,
          requirePhoto: false,
          defaultSortField: 'date',
        ),
      };

  Future<void> _loadConfigs() async {
    // 1. Try to load from backend database first
    try {
      final response = await _dio.get('/screen-configs');
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> decoded = Map<String, dynamic>.from(response.data as Map);
        final configs = decoded.map((key, val) =>
            MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));
        
        state = ScreenConfigState(configs: configs, isLoading: false);

        // Update local storage cache
        try {
          final jsonStr = jsonEncode(configs.map((key, val) => MapEntry(key, val.toJson())));
          await _storageService.write(_storageKey, jsonStr);
        } catch (_) {}
        return;
      }
    } catch (_) {
      // Backend is offline/unreachable, fallback to local storage
    }

    // 2. Local storage fallback
    try {
      final dataStr = await _storageService.read(_storageKey);
      if (dataStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(dataStr);
        final configs = decoded.map((key, val) =>
            MapEntry(key, ScreenConfig.fromJson(val as Map<String, dynamic>)));
        state = ScreenConfigState(configs: configs, isLoading: false);
      } else {
        state = ScreenConfigState(configs: _defaultConfigs, isLoading: false);
      }
    } catch (_) {
      state = ScreenConfigState(configs: _defaultConfigs, isLoading: false);
    }
  }

  Future<void> updateConfig(String docType, ScreenConfig newConfig) async {
    final updatedConfigs = Map<String, ScreenConfig>.from(state.configs);
    updatedConfigs[docType] = newConfig;
    
    state = state.copyWith(configs: updatedConfigs);
    
    // Save locally to storage service (instant UI response)
    try {
      final jsonStr = jsonEncode(updatedConfigs.map((key, val) => MapEntry(key, val.toJson())));
      await _storageService.write(_storageKey, jsonStr);
    } catch (_) {}

    // Save/Sync to the database on the backend
    try {
      await _dio.put('/screen-configs/$docType', data: newConfig.toJson());
    } catch (_) {
      // Offline fallback: keep local cache, next restart or save will try again
    }
  }
}

final screenConfigControllerProvider =
    StateNotifierProvider<ScreenConfigController, ScreenConfigState>((ref) {
  return ScreenConfigController(
    ref.watch(storageServiceProvider),
    ref.watch(dioProvider),
  );
});
