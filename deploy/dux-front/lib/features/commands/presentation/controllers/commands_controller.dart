import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/command.dart';
import '../../data/repositories/commands_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CommandsState {
  final List<Command> commands;
  final bool isLoading;
  final bool isLoadMoreLoading;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final CommandFilter filter;
  final String? error;

  const CommandsState({
    required this.commands,
    this.isLoading = true,
    this.isLoadMoreLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
    this.filter = const CommandFilter(),
    this.error,
  });

  CommandsState copyWith({
    List<Command>? commands,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? hasMore,
    int? page,
    String? searchQuery,
    CommandFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return CommandsState(
      commands: commands ?? this.commands,
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

class CommandsController extends StateNotifier<CommandsState> {
  final Ref _ref;

  // Page size for client-side pagination
  static const int _pageSize = 10;

  CommandsController(this._ref) : super(const CommandsState(commands: [])) {
    fetchCommands();
  }

  Future<void> fetchCommands({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, commands: [], isLoading: true, clearError: true);
    } else if (state.page > 1) {
      state = state.copyWith(isLoadMoreLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final repo = _ref.read(commandsRepositoryProvider);

      // If there's a search query, use it as the document code filter
      final searchFilter = state.searchQuery.isNotEmpty
          ? state.filter.copyWith(documentCode: state.searchQuery)
          : state.filter;

      final authState = _ref.read(authControllerProvider);
      final userStationId = authState.user?.station;
      final userId = authState.user?.id;
      final userTierId = authState.user?.tierId;

      final newCommands = await repo.getCommands(
        filter: searchFilter,
        page: state.page,
        userStationId: userStationId,
        userId: userId,
        userTierId: userTierId,
      );

      // A full page means there might be more; fewer means we've reached the end
      final hasMore = newCommands.length >= _pageSize;

      state = state.copyWith(
        commands: refresh ? newCommands : [...state.commands, ...newCommands],
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
    state = state.copyWith(searchQuery: query, page: 1, commands: []);
    fetchCommands();
  }

  void applyFilter(CommandFilter newFilter) {
    state = state.copyWith(filter: newFilter, page: 1, commands: []);
    fetchCommands();
  }

  void clearFilters() {
    state = state.copyWith(filter: const CommandFilter(), page: 1, commands: []);
    fetchCommands();
  }

  void loadNextPage() {
    if (state.isLoading || state.isLoadMoreLoading || !state.hasMore) return;
    state = state.copyWith(page: state.page + 1);
    fetchCommands();
  }
}

final commandsControllerProvider =
    StateNotifierProvider<CommandsController, CommandsState>((ref) {
  return CommandsController(ref);
});
