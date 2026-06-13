import '../../../commands/domain/models/command.dart';

/// Domain port for command details.
abstract class CommandDetailsRepository {
  Future<Command> getCommandDetails(String id);
}
