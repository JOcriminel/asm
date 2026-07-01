import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/client.dart';
import '../../domain/models/client_filter.dart';
import 'clients_controller.dart';
import '../../../../features/commands/data/repositories/commands_repository.dart';
import '../../../../features/commands/domain/models/command.dart';
import '../../../../features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import '../../../../features/bon_preparation/domain/models/bon_preparation.dart';
import '../../../../features/clients/data/repositories/clients_repository_impl.dart';

class ClientDetailsState {
  final Client? client;
  final bool isLoading;
  final int commandsCount;
  final int preparationsCount;
  final String? error;

  const ClientDetailsState({
    this.client,
    this.isLoading = false,
    this.commandsCount = 0,
    this.preparationsCount = 0,
    this.error,
  });

  ClientDetailsState copyWith({
    Client? client,
    bool? isLoading,
    int? commandsCount,
    int? preparationsCount,
    String? error,
  }) {
    return ClientDetailsState(
      client: client ?? this.client,
      isLoading: isLoading ?? this.isLoading,
      commandsCount: commandsCount ?? this.commandsCount,
      preparationsCount: preparationsCount ?? this.preparationsCount,
      error: error,
    );
  }
}

class ClientDetailsController extends StateNotifier<ClientDetailsState> {
  final Ref _ref;
  final String _clientId;
  final String? _typeTier;

  ClientDetailsController(this._ref, String arg)
      : _clientId = arg.split(':').first,
        _typeTier = arg.contains(':') ? arg.split(':').last : null,
        super(const ClientDetailsState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      Client? client;

      // 1. Try to find client from the in-memory clients list first
      try {
        final clientsState = _ref.read(clientsControllerProvider);
        client = clientsState.clients.firstWhere((c) => c.id == _clientId);
      } catch (_) {}

      // 2. If not found in-memory, fetch it directly from the API using findbycode
      if (client == null) {
        final repository = _ref.read(clientsRepositoryProvider);
        try {
          client = await repository.getClientByCode(_clientId);
        } catch (_) {}
      }

      if (client == null) {
        throw Exception('Client non trouvé');
      }

      state = state.copyWith(client: client);

      // Calculate a safe date range starting from client creation to avoid PHP API crash on massive date ranges
      final fromDate = client.dateCreation ?? DateTime(DateTime.now().year - 1, 1, 1);
      final toDate = DateTime.now();

      final commandsRepo = _ref.read(commandsRepositoryProvider);
      final allCommands = await commandsRepo.getCommands(
        filter: const CommandFilter().copyWith(
          tier: null, // The DUX API crashes if we pass a specific client ID, so we MUST fetch 'all' and filter locally
          allDocuments: false, 
          advancedFilterActive: false, 
          dateFrom: fromDate, 
          dateTo: toDate,
        ),
      );
      final commandsList = allCommands.where((cmd) =>
        cmd.tier == client!.id ||
        cmd.tier == client.code ||
        cmd.customerName == client.nomPrenom ||
        cmd.customerName == client.nomPrenomEdit
      ).toList();
      
      // Fetch preparations count
      final prepRepo = _ref.read(bonPreparationRepositoryProvider);
      final allPreps = await prepRepo.getBonPreparations(
        filter: const BonPreparationFilter().copyWith(
          tier: null, // The DUX API crashes if we pass a specific client ID, so we MUST fetch 'all' and filter locally
          allDocuments: false, 
          advancedFilterActive: false, 
          dateFrom: fromDate, 
          dateTo: toDate,
        ),
      );
      final prepsList = allPreps.where((prep) =>
        prep.tier == client!.id ||
        prep.tier == client.code ||
        prep.customerName == client.nomPrenom ||
        prep.customerName == client.nomPrenomEdit
      ).toList();

      state = state.copyWith(
        commandsCount: commandsList.length,
        preparationsCount: prepsList.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final clientDetailsControllerProvider =
    StateNotifierProvider.autoDispose.family<ClientDetailsController, ClientDetailsState, String>((ref, arg) {
  return ClientDetailsController(ref, arg);
});
