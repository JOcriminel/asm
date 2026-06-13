import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/command.dart';
import '../../domain/repositories/commands_repository.dart';
import '../services/command_api_service.dart';
import '../models/command_dto.dart';
import '../mappers/command_mapper.dart';
import '../../../../core/utils/logger.dart';

/// Concrete implementation of [CommandsRepository].
/// Responsibility: HTTP → DTO → domain entity mapping.
/// Local filtering / pagination live in [CommandApiService] (data-layer concern).
class CommandsRepositoryImpl implements CommandsRepository {
  final CommandApiService _apiService;

  const CommandsRepositoryImpl(this._apiService);

  @override
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    final rawData = await _apiService.fetchCommandsList(
      filter: filter,
      userStationId: userStationId,
      userId: userId,
      userTierId: userTierId,
    );

    final commands = rawData
        .map((e) => CommandMapper.toEntity(CommandDto.fromJson(e as Map<String, dynamic>)))
        .toList();

    AppLogger.d('CommandsRepository', 'Fetched ${commands.length} commands');
    return commands;
  }
}

final commandsRepositoryProvider = Provider<CommandsRepository>((ref) {
  return CommandsRepositoryImpl(ref.watch(commandApiServiceProvider));
});
