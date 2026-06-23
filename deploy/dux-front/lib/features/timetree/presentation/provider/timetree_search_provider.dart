import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';

/// Exposes global search results based on the search query parameter.
final timetreeSearchProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, query) async {
  if (query.trim().length < 2) {
    return {
      'events': [],
      'calendars': [],
      'attachments': [],
      'messages': [],
      'members': [],
    };
  }
  final dio = ref.watch(dioProvider);
  final api = TimetreeApi(dio);
  final response = await api.globalSearch(query);
  
  if (response.data is Map<String, dynamic>) {
    return response.data as Map<String, dynamic>;
  }
  return {
    'events': [],
    'calendars': [],
    'attachments': [],
    'messages': [],
    'members': [],
  };
});
