import '../../domain/models/command.dart';
import '../../domain/repositories/commands_repository.dart';

/// Use-case: retrieve a filtered, paginated list of commands.
/// Encapsulates the fetch contract — controllers call this, never the repository.
class GetCommandsUseCase {
  final CommandsRepository _repository;

  const GetCommandsUseCase(this._repository);

  Future<List<Command>> call({
    required CommandFilter filter,
    required int page,
    int limit = 10,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    final commands = await _repository.getCommands(
      filter: filter,
      userStationId: userStationId,
      userId: userId,
      userTierId: userTierId,
    );

    // Apply local search filter (documentCode query matching)
    var filtered = commands;
    if (filter.documentCode != null && filter.documentCode!.isNotEmpty) {
      final query = filter.documentCode!.toLowerCase();
      filtered = filtered.where((cmd) {
        return cmd.documentCode.toLowerCase().contains(query);
      }).toList();
    }

    // Apply client-side pagination slicing
    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    final end = (start + limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}
