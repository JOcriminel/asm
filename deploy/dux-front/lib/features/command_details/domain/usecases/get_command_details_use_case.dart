import '../../../commands/domain/models/command.dart';
import '../repositories/command_details_repository.dart';

/// Use-case: load full details for a single command.
class GetCommandDetailsUseCase {
  final CommandDetailsRepository _repository;

  const GetCommandDetailsUseCase(this._repository);

  Future<Command> call(String id) => _repository.getCommandDetails(id);
}
