import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
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

class CommandDetailsController extends StateNotifier<CommandDetailsState> {
  final CommandDetailsRepository _repository;

  CommandDetailsController(this._repository, String id) : super(const CommandDetailsState()) {
    fetchDetails(id);
  }

  Future<void> fetchDetails(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final command = await _repository.getCommandDetails(id);
      state = CommandDetailsState(command: command, isLoading: false);
    } catch (e) {
      state = CommandDetailsState(isLoading: false, error: e.toString());
    }
  }
}

final commandDetailsControllerProvider =
    StateNotifierProvider.family<CommandDetailsController, CommandDetailsState, String>((ref, id) {
  final repository = ref.watch(commandDetailsRepositoryProvider);
  return CommandDetailsController(repository, id);
});
