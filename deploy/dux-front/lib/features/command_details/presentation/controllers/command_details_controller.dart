import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
import '../../domain/usecases/get_command_details_use_case.dart';
import '../../data/repositories/command_details_repository.dart';

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

/// Depends on [GetCommandDetailsUseCase] — not on the repository directly.
class CommandDetailsController extends StateNotifier<CommandDetailsState> {
  final GetCommandDetailsUseCase _getCommandDetailsUseCase;

  CommandDetailsController(this._getCommandDetailsUseCase, String id)
      : super(const CommandDetailsState()) {
    fetchDetails(id);
  }

  Future<void> fetchDetails(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final command = await _getCommandDetailsUseCase(id);
      state = CommandDetailsState(command: command, isLoading: false);
    } catch (e) {
      state = CommandDetailsState(isLoading: false, error: e.toString());
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
    id,
  );
});
