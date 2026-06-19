import '../models/bon_sortie.dart';
import '../repositories/bon_sortie_repository.dart';

class GetBonSortiesUseCase {
  final BonSortieRepository _repository;

  const GetBonSortiesUseCase(this._repository);

  Future<List<BonSortie>> call({
    required BonSortieFilter filter,
    required int page,
    int limit = 10,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    final list = await _repository.getBonSorties(
      filter: filter,
      userStationId: userStationId,
      userId: userId,
      userTierId: userTierId,
    );

    // Apply local search query filtering
    var filtered = list;
    if (filter.documentCode != null && filter.documentCode!.isNotEmpty) {
      final query = filter.documentCode!.toLowerCase();
      filtered = filtered.where((e) {
        return e.documentCode.toLowerCase().contains(query) ||
            e.customerName.toLowerCase().contains(query) ||
            e.representative.toLowerCase().contains(query);
      }).toList();
    }

    // Apply client-side pagination slicing
    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    final end = (start + limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}

class GetBonSortieDetailsUseCase {
  final BonSortieRepository _repository;

  const GetBonSortieDetailsUseCase(this._repository);

  Future<BonSortie> call(String id) => _repository.getBonSortieDetails(id);
}
