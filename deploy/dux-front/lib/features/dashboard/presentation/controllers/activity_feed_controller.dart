import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/activity_feed_repository.dart';

class ActivityFeedState {
  final bool isLoading;
  final String? error;
  final List<AuditLogItem> items;
  final int page;
  final bool hasReachedMax;

  ActivityFeedState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.page = 0,
    this.hasReachedMax = false,
  });

  ActivityFeedState copyWith({
    bool? isLoading,
    String? error,
    List<AuditLogItem>? items,
    int? page,
    bool? hasReachedMax,
  }) {
    return ActivityFeedState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class ActivityFeedController extends StateNotifier<ActivityFeedState> {
  final ActivityFeedRepository _repository;

  ActivityFeedController(this._repository) : super(ActivityFeedState()) {
    fetchFeed();
  }

  Future<void> fetchFeed({bool refresh = false}) async {
    if (state.isLoading) return;
    if (state.hasReachedMax && !refresh) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, page: 0, hasReachedMax: false, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final newItems = await _repository.getFeed(page: state.page, size: 20);
      
      state = state.copyWith(
        isLoading: false,
        items: refresh ? newItems : [...state.items, ...newItems],
        page: state.page + 1,
        hasReachedMax: newItems.length < 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final activityFeedControllerProvider = StateNotifierProvider<ActivityFeedController, ActivityFeedState>((ref) {
  final repository = ref.watch(activityFeedRepositoryProvider);
  return ActivityFeedController(repository);
});
