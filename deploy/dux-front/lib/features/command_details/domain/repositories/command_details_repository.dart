import '../../../commands/domain/models/command.dart';

/// Domain port for command details.
abstract class CommandDetailsRepository {
  Future<Command> getCommandDetails(String id);

  Future<List<String>> getSerialNumbersByBonSort(
    String idlignedocument, {
    String? productCode,
    String? lineId,
  });
}
