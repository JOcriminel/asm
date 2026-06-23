import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_menu_item.dart';

/// Provides the list of [TimetreeMenuItem] from the backend endpoint
/// GET /api/timetree/menu.
///
/// Uses the shared [dioProvider] which already has the [AuthInterceptor]
/// and base-URL configured — no local Dio() instantiation.
final timetreeMenuProvider =
    FutureProvider.autoDispose<List<TimetreeMenuItem>>((ref) async {
  // Reuse the shared, auth-intercepted Dio instance.
  final dio = ref.watch(dioProvider);
  final api = TimetreeApi(dio);

  final response = await api.getMenu();

  // The endpoint returns a JSON array at the root level.
  final List<dynamic> jsonList = response.data as List<dynamic>;
  return jsonList
      .map((e) => TimetreeMenuItem.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
});
