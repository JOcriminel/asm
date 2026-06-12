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

class ApiCommandsRepository implements CommandsRepository {
  final CommandApiService _apiService;

  ApiCommandsRepository(this._apiService);

  @override
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    required int page,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    try {
      final rawData = await _apiService.fetchCommandsList(
        filter: filter,
        page: page,
        userStationId: userStationId,
        userId: userId,
        userTierId: userTierId,
      );

      final dtos = rawData.map((e) => CommandDto.fromJson(e as Map<String, dynamic>)).toList();
      final commands = dtos.map((dto) => CommandMapper.toEntity(dto)).toList();
      
      if (commands.isNotEmpty) {
        print('Real result from the API: ${commands.first.toJson()}');
      } else {
        print('Real result from the API is empty');
      }
      
      return commands;
    } catch (e) {
      print('Error fetching real result from API: $e');
      rethrow;
    }
  }
}

final commandsRepositoryProvider = Provider<CommandsRepository>((ref) {
  final apiService = ref.watch(commandApiServiceProvider);
  return ApiCommandsRepository(apiService);
});
