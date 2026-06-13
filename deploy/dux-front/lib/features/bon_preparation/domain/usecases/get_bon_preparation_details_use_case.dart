import '../models/bon_preparation.dart';
import '../repositories/bon_preparation_repository.dart';

class GetBonPreparationDetailsUseCase {
  final BonPreparationRepository _repository;

  const GetBonPreparationDetailsUseCase(this._repository);

  Future<BonPreparation> call(String id) {
    return _repository.getBonPreparationDetails(id);
  }
}
