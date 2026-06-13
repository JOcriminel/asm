import '../models/bon_preparation.dart';
import '../repositories/bon_preparation_repository.dart';

class GetBonPreparationsUseCase {
  final BonPreparationRepository _repository;

  const GetBonPreparationsUseCase(this._repository);

  Future<List<BonPreparation>> call({
    required BonPreparationFilter filter,
    required int page,
    int limit = 10,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    final list = await _repository.getBonPreparations(
      filter: filter,
      userStationId: userStationId,
      userId: userId,
      userTierId: userTierId,
    );

    // Apply local search query filtering (matches document code or customer name)
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
