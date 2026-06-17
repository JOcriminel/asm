import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/client.dart';
import '../../domain/models/client_filter.dart';
import '../../data/repositories/clients_repository_impl.dart';

class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final ClientFilter filter;
  final bool hasReachedMax;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.filter = const ClientFilter(),
    this.hasReachedMax = false,
  });

  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    ClientFilter? filter,
    bool? hasReachedMax,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error, // Can be null to clear
      filter: filter ?? this.filter,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class ClientsController extends StateNotifier<ClientsState> {
  final Ref _ref;
  static const int _pageSize = 20;

  ClientsController(this._ref) : super(const ClientsState()) {
    fetchClients();
  }

  Future<void> fetchClients({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && state.hasReachedMax && state.clients.isNotEmpty) return;

    if (refresh || state.clients.isEmpty) {
      state = state.copyWith(isLoading: true, hasReachedMax: false, error: null);
    } else {
      state = state.copyWith(isFetchingMore: true, error: null);
    }

    try {
      final repository = _ref.read(clientsRepositoryProvider);
      
      final currentCount = refresh ? 0 : state.clients.length;

      final newClients = await repository.getClients(
        filter: state.filter,
        first: currentCount,
        rows: _pageSize,
      );

      state = state.copyWith(
        clients: refresh ? newClients : [...state.clients, ...newClients],
        isLoading: false,
        isFetchingMore: false,
        hasReachedMax: newClients.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        error: e.toString(),
      );
    }
  }

  void updateFilter(ClientFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetchClients(refresh: true);
  }

  void refresh() {
    fetchClients(refresh: true);
  }
}

final clientsControllerProvider =
    StateNotifierProvider.autoDispose<ClientsController, ClientsState>((ref) {
  return ClientsController(ref);
});
