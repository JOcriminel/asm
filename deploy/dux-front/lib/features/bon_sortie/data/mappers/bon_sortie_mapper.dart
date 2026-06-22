import '../../domain/models/bon_sortie.dart';
import '../models/bon_sortie_dto.dart';

class BonSortieMapper {
  static SortieArticle toArticleEntity(SortieArticleDto dto) {
    return SortieArticle(
      id: dto.id ?? '',
      code: dto.code ?? '',
      name: dto.name ?? '',
      quantity: dto.quantity ?? 0,
      unitPrice: dto.unitPrice ?? 0.0,
      unite: dto.unite,
      discountPercent: dto.discountPercent,
      netHT: dto.netHT,
      tvaPercent: dto.tvaPercent,
      puTTC: dto.puTTC,
      totalTTC: dto.totalTTC,
      stock: dto.stock,
      serialNumbers: const [],
      rawJson: dto.rawJson,
      familyId: dto.familyId,
      familyName: dto.familyName,
      numSerie: dto.numSerie,
    );
  }

  static BonSortie toEntity(BonSortieDto dto) {
    final parsedDate = DateTime.tryParse(dto.date ?? '') ?? DateTime.now();
    final timelineCreated = DateTime.tryParse(dto.timeline?.created ?? '');
    final timelineValidated = DateTime.tryParse(dto.timeline?.validated ?? '');
    final timelineDelivered = DateTime.tryParse(dto.timeline?.delivered ?? '');

    return BonSortie(
      id: dto.id ?? '',
      documentCode: dto.documentCode ?? '',
      documentType: dto.documentType ?? '',
      documentTypeCode: dto.documentTypeCode ?? '',
      customerName: dto.customerName ?? '',
      date: parsedDate,
      status: dto.status ?? '',
      statusColor: dto.statusColor ?? '',
      amount: dto.amount ?? 0.0,
      amountTTC: dto.amountTTC ?? 0.0,
      amountTVA: dto.amountTVA ?? 0.0,
      reste: dto.reste ?? 0.0,
      representative: dto.representative ?? '',
      tier: dto.tier ?? '',
      deliveryAddress: dto.deliveryAddress ?? '',
      phone: dto.phone ?? '',
      currency: dto.currency ?? 'DT',
      stationName: dto.stationName ?? '',
      idStation: dto.idStation ?? '',
      articles: dto.articles?.map((e) => toArticleEntity(e)).toList() ?? [],
      timeline: SortieTimeline(
        created: timelineCreated,
        validated: timelineValidated,
        delivered: timelineDelivered,
      ),
      codePiece: dto.codePiece,
      preparedBy: dto.preparedBy,
      concretizedBy: dto.concretizedBy,
      apporteur: dto.apporteur,
      exchangeRate: dto.exchangeRate,
      affecterSur: dto.affecterSur,
      clientRaisonSociale: dto.clientRaisonSociale,
      clientTaxNumber: dto.clientTaxNumber,
      clientAddress: dto.clientAddress,
      clientPhone: dto.clientPhone,
      clientContactPerson: dto.clientContactPerson,
      clientCustomStatus: dto.clientCustomStatus,
      idClassedocument: dto.idClassedocument,
    );
  }
}
