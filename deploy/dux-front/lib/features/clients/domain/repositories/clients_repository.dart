import '../models/client.dart';
import '../models/client_filter.dart';

abstract class ClientsRepository {
  Future<List<Client>> getClients({
    required ClientFilter filter,
    required int first,
    required int rows,
    String? companyId,
    String? userId,
  });
}
