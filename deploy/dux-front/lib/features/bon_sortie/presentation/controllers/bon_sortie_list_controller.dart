import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bon_sortie.dart';
import '../../domain/usecases/get_bon_sorties_use_case.dart';
import '../../data/repositories/bon_sortie_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class BonSortieListState {
  final List<BonSortie> sorties;
  final bool isLoading;
  final bool isLoadMoreLoading;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final BonSortieFilter filter;
  final String? error;

  const BonSortieListState({
    required this.sorties,
    this.isLoading = true,
    this.isLoadMoreLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
    this.filter = const BonSortieFilter(),
    this.error,
  });

  BonSortieListState copyWith({
    List<BonSortie>? sorties,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? hasMore,
    int? page,
    String? searchQuery,
    BonSortieFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return BonSortieListState(
      sorties: sorties ?? this.sorties,
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

class BonSortieListController extends StateNotifier<BonSortieListState> {
  final Ref _ref;
  final GetBonSortiesUseCase _useCase;
  static const int _pageSize = 25;

  BonSortieListController(this._ref, this._useCase)
      : super(const BonSortieListState(sorties: [])) {
    fetchSorties();
  }

  Future<void> fetchSorties({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, sorties: [], isLoading: true, clearError: true);
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
        sorties: combined,
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
    state = state.copyWith(searchQuery: query, page: 1, sorties: []);
    fetchSorties();
  }

  void applyFilter(BonSortieFilter newFilter) {
    state = state.copyWith(filter: newFilter, page: 1, sorties: []);
    fetchSorties();
  }

  void clearFilters() {
    state = state.copyWith(filter: const BonSortieFilter(), page: 1, sorties: []);
    fetchSorties();
  }

  void goToPage(int page) {
    if (state.isLoading || page < 1) return;
    state = state.copyWith(page: page);
    fetchSorties();
  }

  void loadNextPage() {
    if (state.isLoading || state.isLoadMoreLoading || !state.hasMore) return;
    goToPage(state.page + 1);
  }
}

final getBonSortiesUseCaseProvider = Provider<GetBonSortiesUseCase>((ref) {
  return GetBonSortiesUseCase(ref.watch(bonSortieRepositoryProvider));
});

final bonSortieListControllerProvider =
    StateNotifierProvider<BonSortieListController, BonSortieListState>((ref) {
  return BonSortieListController(ref, ref.watch(getBonSortiesUseCaseProvider));
});
