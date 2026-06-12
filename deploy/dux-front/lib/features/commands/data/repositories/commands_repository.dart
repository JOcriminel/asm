import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/command.dart';
import '../services/command_api_service.dart';
import '../models/command_dto.dart';
import '../mappers/command_mapper.dart';

abstract class CommandsRepository {
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    required int page,
    String? userStationId,
    String? userId,
    String? userTierId,
  });
}

class HttpCommandsRepository implements CommandsRepository {
  final CommandApiService _apiService;

  HttpCommandsRepository(this._apiService);

  @override
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    required int page,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    final list = await _apiService.fetchCommandsList(
      filter: filter,
      page: page,
      limit: 10,
      userStationId: userStationId,
      userId: userId,
      userTierId: userTierId,
    );
    return list
        .map((e) => CommandMapper.toEntity(
            CommandDto.fromJson(e as Map<String, dynamic>)))
        .toList();
  }
}

final commandsRepositoryProvider = Provider<CommandsRepository>((ref) {
  final apiService = ref.watch(commandApiServiceProvider);
  return HttpCommandsRepository(apiService);
});
