import '../repositories/bon_preparation_repository.dart';

class SaveSerialNumbersUseCase {
  final BonPreparationRepository _repository;

  const SaveSerialNumbersUseCase(this._repository);

  Future<void> call({
    required String documentId,
    required String lineId,
    required List<String> serialNumbers,
    String? idClassedocument,
    Map<String, dynamic>? rawArticleJson,
  }) {
    return _repository.saveSerialNumbers(
      documentId: documentId,
      lineId: lineId,
      serialNumbers: serialNumbers,
      idClassedocument: idClassedocument,
      rawArticleJson: rawArticleJson,
    );
  }
}
