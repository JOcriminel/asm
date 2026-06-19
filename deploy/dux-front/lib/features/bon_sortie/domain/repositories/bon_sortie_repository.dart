import '../models/bon_sortie.dart';

abstract class BonSortieRepository {
  Future<List<BonSortie>> getBonSorties({
    required BonSortieFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  });

  Future<BonSortie> getBonSortieDetails(String id);

  Future<List<String>> getSerialNumbersByBonSort(
    String idlignedocument, {
    String? productCode,
    String? lineId,
  });
}
