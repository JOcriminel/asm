import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
import '../../domain/usecases/get_command_details_use_case.dart';
import '../../data/repositories/command_details_repository.dart';
import '../../domain/repositories/command_details_repository.dart' as domain;

class CommandDetailsState {
  final Command? command;
  final bool isLoading;
  final String? error;

  const CommandDetailsState({
    this.command,
    this.isLoading = true,
    this.error,
  });

  CommandDetailsState copyWith({
    Command? command,
    bool? isLoading,
    String? error,
  }) {
    return CommandDetailsState(
      command: command ?? this.command,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommandDetailsController extends StateNotifier<CommandDetailsState> {
  final GetCommandDetailsUseCase _getCommandDetailsUseCase;
  final domain.CommandDetailsRepository _repository;
  final String _id;

  CommandDetailsController(
    this._getCommandDetailsUseCase,
    this._repository,
    this._id,
  ) : super(const CommandDetailsState()) {
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final command = await _getCommandDetailsUseCase(_id);
      state = CommandDetailsState(command: command, isLoading: false);
      _autoImportSerialNumbers(command);
    } catch (e) {
      state = CommandDetailsState(isLoading: false, error: e.toString());
    }
  }

  Future<void> _autoImportSerialNumbers(Command command) async {
    List<ArticleItem> updatedArticles = List.from(command.articles);
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
              'CommandDetailsController: Fetched ${fetchedSerials.length} serials for line ${article.id}');
        }
      } catch (e) {
        debugPrint(
            'CommandDetailsController: Failed to fetch serials for line ${article.id}: $e');
      }
    }

    if (updatedAny && mounted) {
      state = state.copyWith(
        command: command.copyWith(articles: updatedArticles),
      );
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _getCommandDetailsUseCaseProvider = Provider<GetCommandDetailsUseCase>((ref) {
  return GetCommandDetailsUseCase(ref.watch(commandDetailsRepositoryProvider));
});

final commandDetailsControllerProvider =
    StateNotifierProvider.family<CommandDetailsController, CommandDetailsState, String>(
        (ref, id) {
  return CommandDetailsController(
    ref.watch(_getCommandDetailsUseCaseProvider),
    ref.watch(commandDetailsRepositoryProvider),
    id,
  );
});
