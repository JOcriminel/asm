import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bon_preparation.dart';
import '../../domain/usecases/get_bon_preparation_details_use_case.dart';
import '../../domain/usecases/save_serial_numbers_use_case.dart';
import '../../domain/repositories/bon_preparation_repository.dart';
import '../../data/repositories/bon_preparation_repository_impl.dart';

class BonPreparationDetailState {
  final BonPreparation? preparation;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const BonPreparationDetailState({
    this.preparation,
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  BonPreparationDetailState copyWith({
    BonPreparation? preparation,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return BonPreparationDetailState(
      preparation: preparation ?? this.preparation,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class BonPreparationDetailController extends StateNotifier<BonPreparationDetailState> {
  final GetBonPreparationDetailsUseCase _getDetailsUseCase;
  final SaveSerialNumbersUseCase _saveSerialNumbersUseCase;
  final BonPreparationRepository _repository;
  final String _id;

  BonPreparationDetailController(
    this._getDetailsUseCase,
    this._saveSerialNumbersUseCase,
    this._repository,
    this._id,
  ) : super(const BonPreparationDetailState()) {
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    debugPrint('DetailController: fetchDetails started for $_id');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final item = await _getDetailsUseCase(_id);
      debugPrint('DetailController: fetchDetails succeeded for $_id');
      
      // Auto-import serial numbers from DUX and await completion
      final itemWithSerials = await _autoImportSerialNumbers(item);
      
      state = BonPreparationDetailState(preparation: itemWithSerials, isLoading: false);
    } catch (e, stack) {
      debugPrint('DetailController: fetchDetails failed for $_id: $e\n$stack');
      state = BonPreparationDetailState(isLoading: false, error: e.toString());
    }
  }

  Future<BonPreparation> _autoImportSerialNumbers(BonPreparation preparation) async {
    final futures = preparation.articles.map((article) async {
      if (article.serialNumbers.isEmpty && article.quantity > 0) {
        try {
          debugPrint('DetailController: Auto-importing serial numbers for line ${article.id} (${article.code})');
          final fetchedSerials = await _repository.getSerialNumbersByBonSort(
            article.id,
            productCode: article.code,
            lineId: article.id,
          );

          if (fetchedSerials.isNotEmpty) {
            debugPrint('DetailController: Fetched ${fetchedSerials.length} serials for line ${article.id}');
            // Limit fetched serials to quantity to prevent overflow
            final toSave = fetchedSerials.take(article.quantity).toList();
            return article.copyWith(serialNumbers: toSave);
          }
        } catch (e) {
          debugPrint('DetailController: Failed to auto-import serials for line ${article.id}: $e');
        }
      }
      return article;
    }).toList();

    final updatedArticles = await Future.wait(futures);
    return preparation.copyWith(articles: updatedArticles);
  }

  Future<bool> saveSerialNumbers({
    required String lineId,
    required List<String> serialNumbers,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      PreparationArticle? article;
      if (state.preparation != null) {
        try {
          article = state.preparation!.articles.firstWhere((art) => art.id == lineId);
        } catch (_) {}
      }
      final rawArticleJson = article?.rawJson;
      final idClassedocument = state.preparation?.idClassedocument;

      await _saveSerialNumbersUseCase(
        documentId: _id,
        lineId: lineId,
        serialNumbers: serialNumbers,
        idClassedocument: idClassedocument,
        rawArticleJson: rawArticleJson,
      );
      
      // Update local state directly for immediate UI feedback before network reload
      if (state.preparation != null) {
        final updatedArticles = state.preparation!.articles.map((art) {
          if (art.id == lineId) {
            return art.copyWith(serialNumbers: serialNumbers);
          }
          return art;
        }).toList();
        state = state.copyWith(
          preparation: state.preparation!.copyWith(articles: updatedArticles),
        );
      }

      // Automatically refresh the entire voucher details asynchronously
      fetchDetails();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSerialNumber(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repository.deleteSerialNumber(id);
      
      // Automatically refresh the entire voucher details
      await fetchDetails();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final getBonPreparationDetailsUseCaseProvider = Provider<GetBonPreparationDetailsUseCase>((ref) {
  return GetBonPreparationDetailsUseCase(ref.watch(bonPreparationRepositoryProvider));
});

final saveSerialNumbersUseCaseProvider = Provider<SaveSerialNumbersUseCase>((ref) {
  return SaveSerialNumbersUseCase(ref.watch(bonPreparationRepositoryProvider));
});

final bonPreparationDetailControllerProvider = StateNotifierProvider.family<
    BonPreparationDetailController, BonPreparationDetailState, String>((ref, id) {
  return BonPreparationDetailController(
    ref.watch(getBonPreparationDetailsUseCaseProvider),
    ref.watch(saveSerialNumbersUseCaseProvider),
    ref.watch(bonPreparationRepositoryProvider),
    id,
  );
});
