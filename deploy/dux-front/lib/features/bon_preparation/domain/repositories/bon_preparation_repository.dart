import '../models/bon_preparation.dart';

abstract class BonPreparationRepository {
  Future<List<BonPreparation>> getBonPreparations({
    required BonPreparationFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  });

  Future<BonPreparation> getBonPreparationDetails(String id);

  Future<void> saveSerialNumbers({
    required String documentId,
    required String lineId,
    required List<String> serialNumbers,
    String? idClassedocument,
    Map<String, dynamic>? rawArticleJson,
  });

  Future<List<String>> getSerialNumbersByBonSort(
    String idlignedocument, {
    String? productCode,
    String? lineId,
  });

  Future<Map<String, String>> getSerialNumberIds(String idlignedocument);

  Future<void> deleteSerialNumber(String id);

  Future<void> updateDocumentStatus(String documentId, String newStatusId, Map<String, dynamic> currentDocData);
  Future<Map<String, dynamic>?> getValidationProof(String documentId);
}
