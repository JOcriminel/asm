import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/command.dart';

abstract class CommandsRepository {
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    required int page,
    String? userStationId,
    String? userId,
    String? userTierId,
  });
}

class MockCommandsRepository implements CommandsRepository {
  @override
  Future<List<Command>> getCommands({
    required CommandFilter filter,
    required int page,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return empty list if we are past page 3 for demonstration
    if (page > 3) return [];

    final dummyCommands = List.generate(
      10,
      (index) {
        final idStr = ((page - 1) * 10 + index + 1).toString();
        return Command(
          id: idStr,
          documentCode: 'CMD-${idStr.padLeft(4, '0')}',
          documentType: 'Bon de Commande Client',
          documentTypeCode: 'BCC',
          customerName: 'Client $idStr',
          date: DateTime.now().subtract(Duration(days: index)),
          status: index % 3 == 0 ? 'Livré' : (index % 2 == 0 ? 'En cours' : 'Validé'),
          statusColor: index % 3 == 0 ? '#4CAF50' : (index % 2 == 0 ? '#FF9800' : '#2196F3'),
          amount: 100.0 * (index + 1),
          amountTTC: 119.0 * (index + 1),
          amountTVA: 19.0 * (index + 1),
          reste: index % 4 == 0 ? 0.0 : 50.0,
          representative: 'Représentant A',
          tier: 'Tier $idStr',
          deliveryAddress: 'Adresse $idStr, Ville',
          phone: '12345678',
          currency: 'DT',
          stationName: 'Station Principale',
          idStation: '1',
          articles: [
            ArticleItem(
              id: 'A1',
              code: 'ART01',
              name: 'Article Test 1',
              quantity: 2,
              unitPrice: 25.0 * (index + 1),
            ),
            ArticleItem(
              id: 'A2',
              code: 'ART02',
              name: 'Article Test 2',
              quantity: 1,
              unitPrice: 50.0 * (index + 1),
            ),
          ],
          timeline: CommandTimeline(
            created: DateTime.now().subtract(Duration(days: index, hours: 2)),
            validated: index % 2 != 0 ? DateTime.now().subtract(Duration(days: index, hours: 1)) : null,
            delivered: index % 3 == 0 ? DateTime.now().subtract(Duration(days: index)) : null,
          ),
          classeDocument: const ClasseDocument(
            id: 'CD1',
            code: 'BCC',
            libelle: 'Bon de Commande Client',
            isVente: true,
          ),
        );
      },
    );

    // Apply basic filtering for demonstration
    Iterable<Command> filtered = dummyCommands;
    if (filter.documentCode != null && filter.documentCode!.isNotEmpty) {
      filtered = filtered.where((c) =>
          c.documentCode.toLowerCase().contains(filter.documentCode!.toLowerCase()));
    }
    if (filter.status != null && filter.status!.isNotEmpty) {
      filtered = filtered.where((c) => c.status == filter.status);
    }

    return filtered.toList();
  }
}

final commandsRepositoryProvider = Provider<CommandsRepository>((ref) {
  return MockCommandsRepository();
});
