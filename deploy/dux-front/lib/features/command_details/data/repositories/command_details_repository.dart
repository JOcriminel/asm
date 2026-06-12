import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commands/domain/models/command.dart';

abstract class CommandDetailsRepository {
  Future<Command> getCommandDetails(String id);
}

class MockCommandDetailsRepository implements CommandDetailsRepository {
  @override
  Future<Command> getCommandDetails(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Return dummy command details
    return Command(
      id: id,
      documentCode: 'CMD-${id.padLeft(4, '0')}',
      documentType: 'Bon de Commande Client',
      documentTypeCode: 'BCC',
      customerName: 'Client $id',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Validé',
      statusColor: '#2196F3',
      amount: 500.0,
      amountTTC: 595.0,
      amountTVA: 95.0,
      reste: 50.0,
      representative: 'Représentant A',
      tier: 'Tier $id',
      deliveryAddress: 'Adresse $id, Ville, Pays',
      phone: '+216 12 345 678',
      currency: 'DT',
      stationName: 'Station Principale',
      idStation: '1',
      articles: [
        const ArticleItem(
          id: 'A1',
          code: 'ART01',
          name: 'Produit Premium A',
          quantity: 2,
          unitPrice: 150.0,
        ),
        const ArticleItem(
          id: 'A2',
          code: 'ART02',
          name: 'Accessoire Standard B',
          quantity: 4,
          unitPrice: 50.0,
        ),
      ],
      timeline: CommandTimeline(
        created: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        validated: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        delivered: null,
      ),
      classeDocument: const ClasseDocument(
        id: 'CD1',
        code: 'BCC',
        libelle: 'Bon de Commande Client',
        isVente: true,
      ),
    );
  }
}

final commandDetailsRepositoryProvider = Provider<CommandDetailsRepository>((ref) {
  return MockCommandDetailsRepository();
});
