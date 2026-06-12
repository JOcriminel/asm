import '../../domain/models/command.dart';
import '../models/command_dto.dart';

class CommandMapper {
  static Command toEntity(CommandDto dto) {
    return Command(
      id: dto.id ?? '',
      documentCode: dto.documentCode ?? 'N/A',
      documentType: dto.documentType ?? '',
      documentTypeCode: dto.documentTypeCode ?? '',
      customerName: dto.customerName ?? 'Client inconnu',
      date: _parseDate(dto.date),
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
      articles: dto.articles
              ?.map((e) => ArticleItem(
                    id: e.id ?? '',
                    code: e.code ?? '',
                    name: e.name ?? 'Article inconnu',
                    quantity: e.quantity ?? 0,
                    unitPrice: e.unitPrice ?? 0.0,
                    unite: e.unite,
                    discountPercent: e.discountPercent,
                    netHT: e.netHT,
                    tvaPercent: e.tvaPercent,
                    puTTC: e.puTTC,
                    totalTTC: e.totalTTC,
                    stock: e.stock,
                  ))
              .toList() ??
          [],
      // New detailed fields
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
      timeline: CommandTimeline(
        created: dto.timeline?.created != null
            ? _parseDate(dto.timeline!.created)
            : null,
        validated: dto.timeline?.validated != null
            ? _parseDate(dto.timeline!.validated)
            : null,
        delivered: dto.timeline?.delivered != null
            ? _parseDate(dto.timeline!.delivered)
            : null,
      ),
      classeDocument: dto.classeDocument != null
          ? ClasseDocument(
              id: dto.classeDocument!.id ?? '',
              version: dto.classeDocument!.version ?? 0,
              code: dto.classeDocument!.code ?? '',
              libelle: dto.classeDocument!.libelle ?? '',
              titre: dto.classeDocument!.titre ?? '',
              titreImprimable: dto.classeDocument!.titreImprimable ?? '',
              affecteStock: dto.classeDocument!.affecteStock ?? false,
              affecteSolde: dto.classeDocument!.affecteSolde ?? false,
              affectecmp: dto.classeDocument!.affectecmp ?? false,
              isInput: dto.classeDocument!.isInput ?? false,
              isOutput: dto.classeDocument!.isOutput ?? false,
              idTypeCalcul: dto.classeDocument!.idTypeCalcul ?? '',
              isAchat: dto.classeDocument!.isAchat ?? false,
              isVente: dto.classeDocument!.isVente ?? false,
              useMainStationRegime: dto.classeDocument!.useMainStationRegime ?? false,
              prefixe: dto.classeDocument!.prefixe ?? '',
              numAtteint: dto.classeDocument!.numAtteint ?? 0,
              isTvaConsider: dto.classeDocument!.isTvaConsider ?? true,
              isReglable: dto.classeDocument!.isReglable ?? true,
              isFacturable: dto.classeDocument!.isFacturable ?? false,
              useDestination: dto.classeDocument!.useDestination ?? false,
              isFacture: dto.classeDocument!.isFacture ?? false,
              isAvoir: dto.classeDocument!.isAvoir ?? false,
              isRepDachat: dto.classeDocument!.isRepDachat ?? false,
              transformable: dto.classeDocument!.transformable ?? true,
              couleur: dto.classeDocument!.couleur ?? '',
            )
          : null,
    );
  }

  /// Parse DUX date strings that can be either:
  ///   ISO 8601:       "2026-06-11T12:08:22.000"
  ///   DUX SQL format: "2026-06-11 12:08:22.000"
  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final normalized = raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? DateTime.now();
  }
}
