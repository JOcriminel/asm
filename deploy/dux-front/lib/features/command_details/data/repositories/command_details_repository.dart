import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';
import '../../../commands/data/models/command_dto.dart';
import '../../../commands/data/mappers/command_mapper.dart';
import '../../domain/repositories/command_details_repository.dart';
import '../services/command_details_api_service.dart';

/// Concrete implementation of [CommandDetailsRepository].
class CommandDetailsRepositoryImpl implements CommandDetailsRepository {
  final CommandDetailsApiService _apiService;

  const CommandDetailsRepositoryImpl(this._apiService);

  @override
  Future<Command> getCommandDetails(String id) async {
    final rawData = await _apiService.fetchCommandDetails(id);
    final dto = CommandDto.fromJson(rawData);
    return CommandMapper.toEntity(dto);
  }
}

final commandDetailsRepositoryProvider = Provider<CommandDetailsRepository>((ref) {
  return CommandDetailsRepositoryImpl(ref.watch(commandDetailsApiServiceProvider));
});
