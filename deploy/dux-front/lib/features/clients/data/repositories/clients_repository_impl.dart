import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/client.dart';
import '../../domain/models/client_filter.dart';
import '../../domain/repositories/clients_repository.dart';
import '../services/client_api_service.dart';
import '../models/client_dto.dart';
import '../mappers/client_mapper.dart';
import '../../../../core/utils/logger.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientApiService _apiService;

  const ClientsRepositoryImpl(this._apiService);

  @override
  Future<List<Client>> getClients({
    required ClientFilter filter,
    required int first,
    required int rows,
    String? companyId,
    String? userId,
  }) async {
    final rawData = await _apiService.fetchClientsList(
      filter: filter,
      first: first,
      rows: rows,
      companyId: companyId,
      userId: userId,
    );

    final clients = rawData
        .map((e) => ClientMapper.toEntity(ClientDto.fromJson(e as Map<String, dynamic>)))
        .toList();

    AppLogger.d('ClientsRepository', 'Fetched ${clients.length} clients');
    return clients;
  }

  @override
  Future<Client> getClientByCode(String code) async {
    final raw = await _apiService.fetchClientByCode(code);
    return ClientMapper.toEntity(ClientDto.fromJson(raw));
  }
}

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepositoryImpl(ref.watch(clientApiServiceProvider));
});
