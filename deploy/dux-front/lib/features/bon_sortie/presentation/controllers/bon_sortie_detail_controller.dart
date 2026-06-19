import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bon_sortie.dart';
import '../../domain/usecases/get_bon_sorties_use_case.dart';
import '../../domain/repositories/bon_sortie_repository.dart';
import '../../data/repositories/bon_sortie_repository_impl.dart';

class BonSortieDetailState {
  final BonSortie? sortie;
  final bool isLoading;
  final String? error;

  const BonSortieDetailState({
    this.sortie,
    this.isLoading = true,
    this.error,
  });

  BonSortieDetailState copyWith({
    BonSortie? sortie,
    bool? isLoading,
    String? error,
  }) {
    return BonSortieDetailState(
      sortie: sortie ?? this.sortie,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BonSortieDetailController extends StateNotifier<BonSortieDetailState> {
  final GetBonSortieDetailsUseCase _getDetailsUseCase;
  final BonSortieRepository _repository;
  final String _id;

  BonSortieDetailController(this._getDetailsUseCase, this._repository, this._id)
      : super(const BonSortieDetailState()) {
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    debugPrint('BonSortieDetailController: fetchDetails started for $_id');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final item = await _getDetailsUseCase(_id);
      debugPrint('BonSortieDetailController: fetchDetails succeeded for $_id');
      state = BonSortieDetailState(sortie: item, isLoading: false);
      // Auto-import serial numbers for all articles
      _autoImportSerialNumbers(item);
    } catch (e, stack) {
      debugPrint('BonSortieDetailController: fetchDetails failed for $_id: $e\n$stack');
      state = BonSortieDetailState(isLoading: false, error: e.toString());
    }
  }

  Future<void> _autoImportSerialNumbers(BonSortie sortie) async {
    List<SortieArticle> updatedArticles = List.from(sortie.articles);
    bool updatedAny = false;

    for (int i = 0; i < updatedArticles.length; i++) {
      final article = updatedArticles[i];
      try {
        final fetchedSerials = await _repository.getSerialNumbersByBonSort(
          article.id,
          productCode: article.code,
          lineId: article.id,
        );
        if (fetchedSerials.isNotEmpty) {
          updatedArticles[i] = article.copyWith(serialNumbers: fetchedSerials);
          updatedAny = true;
          debugPrint(
              'BonSortieDetailController: Fetched ${fetchedSerials.length} serials for line ${article.id}');
        }
      } catch (e) {
        debugPrint(
            'BonSortieDetailController: Failed to fetch serials for line ${article.id}: $e');
      }
    }

    if (updatedAny && mounted) {
      state = state.copyWith(
        sortie: sortie.copyWith(articles: updatedArticles),
      );
    }
  }
}

final getBonSortieDetailsUseCaseProvider = Provider<GetBonSortieDetailsUseCase>((ref) {
  return GetBonSortieDetailsUseCase(ref.watch(bonSortieRepositoryProvider));
});

final bonSortieDetailControllerProvider =
    StateNotifierProvider.family<BonSortieDetailController, BonSortieDetailState, String>(
  (ref, id) => BonSortieDetailController(
    ref.watch(getBonSortieDetailsUseCaseProvider),
    ref.watch(bonSortieRepositoryProvider),
    id,
  ),
);
