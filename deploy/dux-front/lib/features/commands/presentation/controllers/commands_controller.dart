import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/command.dart';
import '../../domain/usecases/get_commands_use_case.dart';
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

/// Presentation controller for the commands list.
/// Depends only on [GetCommandsUseCase] — Dependency Inversion applied.
class CommandsController extends StateNotifier<CommandsState> {
  final Ref _ref;
  final GetCommandsUseCase _getCommandsUseCase;

  static const int _pageSize = 25;

  CommandsController(this._ref, this._getCommandsUseCase)
      : super(const CommandsState(commands: [])) {
    fetchCommands();
  }

  Future<void> fetchCommands({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, commands: [], isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final searchFilter = state.searchQuery.isNotEmpty
          ? state.filter.copyWith(documentCode: state.searchQuery)
          : state.filter;

      final authState = _ref.read(authControllerProvider);

      final newCommands = await _getCommandsUseCase(
        filter: searchFilter,
        page: state.page,
        limit: _pageSize,
        userStationId: authState.user?.station,
        userId: authState.user?.id,
        userTierId: authState.user?.tierId,
      );

      final hasMore = newCommands.length >= _pageSize;
      final combined = newCommands;
      _applySort(combined, state.filter.sortOrder);

      state = state.copyWith(
        commands: combined,
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
    final old = state.filter;
    final onlySortChanged = old.dateFrom == newFilter.dateFrom &&
        old.dateTo == newFilter.dateTo &&
        old.tier == newFilter.tier &&
        old.representative == newFilter.representative &&
        old.documentCode == newFilter.documentCode &&
        old.status == newFilter.status &&
        old.allDocuments == newFilter.allDocuments &&
        old.articleFilter == newFilter.articleFilter &&
        old.advancedFilterActive == newFilter.advancedFilterActive;

    if (onlySortChanged && old.sortOrder != newFilter.sortOrder) {
      state = state.copyWith(filter: newFilter);
      _sortCommandsLocally();
      return;
    }

    state = state.copyWith(filter: newFilter, page: 1, commands: []);
    fetchCommands();
  }

  void clearFilters() {
    state = state.copyWith(filter: const CommandFilter(), page: 1, commands: []);
    fetchCommands();
  }

  void goToPage(int page) {
    if (state.isLoading || page < 1) return;
    state = state.copyWith(page: page);
    fetchCommands();
  }

  void loadNextPage() {
    if (state.isLoading || state.isLoadMoreLoading || !state.hasMore) return;
    goToPage(state.page + 1);
  }

  void _sortCommandsLocally() {
    final sorted = List<Command>.from(state.commands);
    _applySort(sorted, state.filter.sortOrder);
    state = state.copyWith(commands: sorted);
  }

  void _applySort(List<Command> list, CommandSortOrder sortOrder) {
    switch (sortOrder) {
      case CommandSortOrder.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
      case CommandSortOrder.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
      case CommandSortOrder.amountDesc:
        list.sort((a, b) => b.amountTTC.compareTo(a.amountTTC));
      case CommandSortOrder.amountAsc:
        list.sort((a, b) => a.amountTTC.compareTo(b.amountTTC));
      case CommandSortOrder.nameAsc:
        list.sort((a, b) => a.customerName.compareTo(b.customerName));
      case CommandSortOrder.nameDesc:
        list.sort((a, b) => b.customerName.compareTo(a.customerName));
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _getCommandsUseCaseProvider = Provider<GetCommandsUseCase>((ref) {
  return GetCommandsUseCase(ref.watch(commandsRepositoryProvider));
});

final commandsControllerProvider =
    StateNotifierProvider<CommandsController, CommandsState>((ref) {
  return CommandsController(ref, ref.watch(_getCommandsUseCaseProvider));
});
