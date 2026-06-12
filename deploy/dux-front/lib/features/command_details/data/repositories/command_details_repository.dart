import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
import '../../../commands/data/models/command_dto.dart';
import '../../../commands/data/mappers/command_mapper.dart';
import '../services/command_details_api_service.dart';

abstract class CommandDetailsRepository {
  Future<Command> getCommandDetails(String id);
}

class HttpCommandDetailsRepository implements CommandDetailsRepository {
  final CommandDetailsApiService _apiService;

  HttpCommandDetailsRepository(this._apiService);

  @override
  Future<Command> getCommandDetails(String id) async {
    final data = await _apiService.fetchCommandDetails(id);
    final dto = CommandDto.fromJson(data);
    return CommandMapper.toEntity(dto);
  }
}

final commandDetailsRepositoryProvider = Provider<CommandDetailsRepository>((ref) {
  final apiService = ref.watch(commandDetailsApiServiceProvider);
  return HttpCommandDetailsRepository(apiService);
});
