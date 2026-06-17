import 'package:dux_front/core/services/serial_number_cache_service.dart';
import '../models/bon_preparation.dart';
import '../repositories/bon_preparation_repository.dart';

class GetBonPreparationsUseCase {
  final BonPreparationRepository _repository;
  final SerialNumberCacheService _cacheService;

  const GetBonPreparationsUseCase(this._repository, this._cacheService);

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
        final matchesDocOrName = e.documentCode.toLowerCase().contains(query) ||
            e.customerName.toLowerCase().contains(query) ||
            e.representative.toLowerCase().contains(query);
            
        if (matchesDocOrName) return true;
        
        // Also search in article's numSerie or serialNumbers (if already present in list)
        return e.articles.any((a) {
          if (a.numSerie != null && a.numSerie!.toLowerCase().contains(query)) return true;
          if (a.serialNumbers.any((sn) => sn.toLowerCase().contains(query))) return true;
          return false;
        });
      }).toList();

      // --- RECHERCHE DANS LE CACHE LOCAL ---
      if (filtered.isEmpty) {
        final cachedDocId = await _cacheService.findDocumentId(query);
        if (cachedDocId != null) {
          final matchedBp = list.where((bp) => bp.id == cachedDocId).toList();
          if (matchedBp.isNotEmpty) {
            filtered = matchedBp;
          }
        }
      }

      // --- DEEP SEARCH EN LOTS (CHUNKS) ---
      // Si la recherche locale n'a rien donné, on fait un "Deep Search".
      // Au lieu de limiter à 30, on peut chercher dans toute la liste (jusqu'à 500),
      // mais on le fait par paquets de 15 requêtes simultanées pour ne pas crasher le serveur.
      if (filtered.isEmpty) {
        final List<BonPreparation> deepFound = [];
        const chunkSize = 15;
        
        // On parcours la liste complète par blocs
        for (int i = 0; i < list.length; i += chunkSize) {
          final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
          final chunk = list.sublist(i, end);

          await Future.wait(chunk.map((bp) async {
            try {
              final details = await _repository.getBonPreparationDetails(bp.id);
              bool found = false;

              for (var a in details.articles) {
                if ((a.numSerie != null && a.numSerie!.toLowerCase().contains(query)) ||
                    (a.serialNumbers.any((sn) => sn.toLowerCase().contains(query)))) {
                  found = true;
                  break;
                }
              }

              if (!found) {
                final snChecks = await Future.wait(details.articles.map((a) async {
                  if (!a.hasSerialNumbers) return false;
                  try {
                    final sns = await _repository.getSerialNumbersByBonSort(a.id, productCode: a.code, lineId: a.id);
                    return sns.any((sn) => sn.toLowerCase().contains(query));
                  } catch (_) {
                    return false;
                  }
                }));
                if (snChecks.any((match) => match)) found = true;
              }

              if (found) {
                deepFound.add(bp);
              }
            } catch (_) {
              // Ignore failures for individual fetches
            }
          }));

          // Dès qu'on a trouvé au moins un résultat dans ce lot, on s'arrête !
          // Ça évite de faire des requêtes inutiles si le BP était dans les 15 premiers.
          if (deepFound.isNotEmpty) {
            break;
          }
        }

        if (deepFound.isNotEmpty) {
          filtered = deepFound;
        }
      }
    }

    // Apply client-side pagination slicing
    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    final end = (start + limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}
