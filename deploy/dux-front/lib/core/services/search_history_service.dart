import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

const String _kSearchHistoryKey = 'search_history';

class SearchHistoryService extends StateNotifier<List<String>> {
  final StorageService _storage;

  SearchHistoryService(this._storage) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final jsonStr = await _storage.read(_kSearchHistoryKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final newList = List<String>.from(state);
    newList.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    newList.insert(0, trimmed);
    
    if (newList.length > 5) {
      newList.removeRange(5, newList.length);
    }

    state = newList;
    await _storage.write(_kSearchHistoryKey, jsonEncode(state));
  }

  Future<void> removeSearchQuery(String query) async {
    final newList = List<String>.from(state);
    newList.removeWhere((q) => q.toLowerCase() == query.toLowerCase());
    state = newList;
    await _storage.write(_kSearchHistoryKey, jsonEncode(state));
  }

  Future<void> clearHistory() async {
    state = [];
    await _storage.delete(_kSearchHistoryKey);
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryService, List<String>>((ref) {
  final storage = ref.read(storageServiceProvider);
  return SearchHistoryService(storage);
});
