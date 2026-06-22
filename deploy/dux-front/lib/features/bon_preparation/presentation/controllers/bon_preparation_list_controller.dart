import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bon_preparation.dart';
import '../../domain/usecases/get_bon_preparations_use_case.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/serial_number_cache_service.dart';
import '../../../checklist/presentation/controllers/checklist_response_controller.dart';

class BonPreparationListState {
  final List<BonPreparation> preparations;
  final bool isLoading;
  final bool isLoadMoreLoading;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final BonPreparationFilter filter;
  final String? error;

  const BonPreparationListState({
    required this.preparations,
    this.isLoading = true,
    this.isLoadMoreLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
    this.filter = const BonPreparationFilter(),
    this.error,
  });

  BonPreparationListState copyWith({
    List<BonPreparation>? preparations,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? hasMore,
    int? page,
    String? searchQuery,
    BonPreparationFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return BonPreparationListState(
      preparations: preparations ?? this.preparations,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BonPreparationListController extends StateNotifier<BonPreparationListState> {
  final Ref _ref;
  final GetBonPreparationsUseCase _useCase;
  static const int _pageSize = 25;

  BonPreparationListController(this._ref, this._useCase)
      : super(const BonPreparationListState(preparations: [])) {
    fetchPreparations();
  }

  Future<void> fetchPreparations({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, preparations: [], isLoading: true, clearError: true);
      _ref.invalidate(bonPreparationDetailsProvider);
      _ref.invalidate(documentChecklistCountProvider);
      _ref.invalidate(articleChecklistCountProvider);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final searchFilter = state.searchQuery.isNotEmpty
          ? state.filter.copyWith(documentCode: state.searchQuery)
          : state.filter;

      final authState = _ref.read(authControllerProvider);

      final newItems = await _useCase(
        filter: searchFilter,
        page: state.page,
        limit: _pageSize,
        userStationId: authState.user?.station,
        userId: authState.user?.id,
        userTierId: authState.user?.tierId,
      );

      final hasMore = newItems.length >= _pageSize;
      final combined = newItems;

      state = state.copyWith(
        preparations: combined,
        isLoading: false,
        isLoadMoreLoading: false,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMoreLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query, page: 1, preparations: []);
    fetchPreparations();
  }

  void applyFilter(BonPreparationFilter newFilter) {
    state = state.copyWith(filter: newFilter, page: 1, preparations: []);
    fetchPreparations();
  }

  void clearFilters() {
    state = state.copyWith(filter: const BonPreparationFilter(), page: 1, preparations: []);
    fetchPreparations();
  }

  void goToPage(int page) {
    if (state.isLoading || page < 1) return;
    state = state.copyWith(page: page);
    fetchPreparations();
  }

  void loadNextPage() {
    if (state.isLoading || state.isLoadMoreLoading || !state.hasMore) return;
    goToPage(state.page + 1);
  }
}

final getBonPreparationsUseCaseProvider = Provider<GetBonPreparationsUseCase>((ref) {
  return GetBonPreparationsUseCase(
    ref.watch(bonPreparationRepositoryProvider),
    ref.watch(serialNumberCacheServiceProvider),
  );
});

final bonPreparationListControllerProvider =
    StateNotifierProvider<BonPreparationListController, BonPreparationListState>((ref) {
  return BonPreparationListController(ref, ref.watch(getBonPreparationsUseCaseProvider));
});
