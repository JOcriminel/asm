import '../../domain/models/command.dart';

/// Domain port for the commands list.
/// Implementations live in data/repositories/.
abstract class CommandsRepository {
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  });
}

