double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  final d = double.tryParse(s);
  if (d != null) return d.toInt();
  return int.tryParse(s);
}

class PreparationArticleDto {
  final String? id;
  final String? code;
  final String? name;
  final int? quantity;
  final double? unitPrice;
  final String? unite;
  final double? discountPercent;
  final double? netHT;
  final double? tvaPercent;
  final double? puTTC;
  final double? totalTTC;
  final String? stock;
  final List<String>? serialNumbers;
  final Map<String, dynamic>? rawJson;
  final String? numSerie;
  final String? familyId;
  final String? familyName;

  PreparationArticleDto({
    this.id,
    this.code,
    this.name,
    this.quantity,
    this.unitPrice,
    this.unite,
    this.discountPercent,
    this.netHT,
    this.tvaPercent,
    this.puTTC,
    this.totalTTC,
    this.stock,
    this.serialNumbers,
    this.rawJson,
    this.numSerie,
    this.familyId,
    this.familyName,
  });

  factory PreparationArticleDto.fromJson(Map<String, dynamic> json) {
    // Parse serial numbers which can be list of items or comma-separated string
    final rawSn =
        json['listNumSerie'] ??
        json['serialNumbers'] ??
        json['numSeries'] ??
        json['numerosSerie'] ??
        json['numsSerie'] ??
        json['serial_numbers'];

    List<String> serials = [];
    if (rawSn is List) {
      serials = rawSn
          .map((e) {
            if (e is Map) {
              return (e['NumSerie'] ?? e['numSerie'] ?? e['num_serie'] ?? '')
                  .toString()
                  .trim();
            }
            return e.toString().trim();
          })
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } else if (rawSn is String) {
      serials = rawSn
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    return PreparationArticleDto(
      id:
          json['id']?.toString() ??
          json['idLigne']?.toString() ??
          json['idLigneDocument']?.toString() ??
          json['idlignedocument']?.toString() ??
          json['idligne']?.toString() ??
          json['idArticle']?.toString(),
      code:
          json['code']?.toString() ??
          json['codeArticle']?.toString() ??
          json['ref']?.toString(),
      name:
          json['name']?.toString() ??
          json['libelle']?.toString() ??
          json['libelleArticle']?.toString() ??
          json['libelleCourte']?.toString() ??
          json['designation']?.toString() ??
          json['libArticle']?.toString(),
      quantity:
          _toInt(json['quantity']) ??
          _toInt(json['qte']) ??
          _toInt(json['quantite']) ??
          _toInt(json['qteLigne']) ??
          _toInt(json['QteLigne']) ??
          _toInt(json['qteLigneDocument']),
      unitPrice:
          _toDouble(json['unitPrice']) ??
          _toDouble(json['puht']) ??
          _toDouble(json['prix']) ??
          _toDouble(json['pu']) ??
          _toDouble(json['prixUnitaire']),
      unite: json['libelleUnite']?.toString() ?? json['unite']?.toString(),
      discountPercent:
          _toDouble(json['tauxRemise']) ?? _toDouble(json['discountPercent']),
      netHT: _toDouble(json['mntNetht']) ?? _toDouble(json['netHT']),
      tvaPercent: _toDouble(json['tauxTva']) ?? _toDouble(json['tvaPercent']),
      puTTC: _toDouble(json['puttc']) ?? _toDouble(json['puTTC']),
      totalTTC: _toDouble(json['mntttc']) ?? _toDouble(json['totalTTC']),
      stock: json['isStockable']?.toString() ?? json['stock']?.toString(),
      serialNumbers: serials,
      rawJson: json,
      numSerie: json['NumSerie']?.toString() ?? json['numSerie']?.toString(),
      familyId: json['idFamille']?.toString() ?? json['idFamilleArticle']?.toString() ?? json['codeFamille']?.toString() ?? json['famille']?.toString(),
      familyName: json['libelleFamille']?.toString() ?? json['familyName']?.toString() ?? json['nomFamille']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'unite': unite,
    'discountPercent': discountPercent,
    'netHT': netHT,
    'tvaPercent': tvaPercent,
    'puTTC': puTTC,
    'totalTTC': totalTTC,
    'stock': stock,
    'serialNumbers': serialNumbers,
    'rawJson': rawJson,
    'numSerie': numSerie,
    'familyId': familyId,
    'familyName': familyName,
  };
}

class PreparationTimelineDto {
  final String? created;
  final String? validated;
  final String? delivered;

  PreparationTimelineDto({this.created, this.validated, this.delivered});

  factory PreparationTimelineDto.fromJson(Map<String, dynamic> json) {
    return PreparationTimelineDto(
      created:
          json['created']?.toString() ??
          json['dateCreation']?.toString() ??
          json['dateSaisie']?.toString() ??
          json['dateDocument']?.toString(),
      validated:
          json['validated']?.toString() ?? json['dateValidation']?.toString(),
      delivered:
          json['delivered']?.toString() ?? json['dateLivraison']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'created': created,
    'validated': validated,
    'delivered': delivered,
  };
}

class BonPreparationDto {
  final String? id;
  final String? documentCode;
  final String? customerName;
  final String? date;
  final String? status;
  final String? statusColor;
  final double? amount;
  final double? amountTTC;
  final double? amountTVA;
  final double? reste;
  final String? representative;
  final String? tier;
  final String? tierName;
  final String? deliveryAddress;
  final String? phone;
  final String? documentType;
  final String? documentTypeCode;
  final String? stationName;
  final String? idStation;
  final String? currency;
  final List<PreparationArticleDto>? articles;
  final PreparationTimelineDto? timeline;

  final String? codePiece;
  final String? preparedBy;
  final String? concretizedBy;
  final String? apporteur;
  final double? exchangeRate;
  final String? affecterSur;
  final String? clientRaisonSociale;
  final String? clientTaxNumber;
  final String? clientAddress;
  final String? clientPhone;
  final String? clientContactPerson;
  final String? clientCustomStatus;
  final String? idClassedocument;

  BonPreparationDto({
    this.id,
    this.documentCode,
    this.customerName,
    this.date,
    this.status,
    this.statusColor,
    this.amount,
    this.amountTTC,
    this.amountTVA,
    this.reste,
    this.representative,
    this.tier,
    this.tierName,
    this.deliveryAddress,
    this.phone,
    this.documentType,
    this.documentTypeCode,
    this.stationName,
    this.idStation,
    this.currency,
    this.articles,
    this.timeline,
    this.codePiece,
    this.preparedBy,
    this.concretizedBy,
    this.apporteur,
    this.exchangeRate,
    this.affecterSur,
    this.clientRaisonSociale,
    this.clientTaxNumber,
    this.clientAddress,
    this.clientPhone,
    this.clientContactPerson,
    this.clientCustomStatus,
    this.idClassedocument,
  });

  factory BonPreparationDto.fromJson(Map<String, dynamic> json) {
    final rawArticles =
        json['articles'] as List? ??
        json['listeArticles'] as List? ??
        json['lignes'] as List? ??
        json['details'] as List? ??
        json['lignesDoc'] as List?;

    final articlesDtos =
        rawArticles
            ?.map(
              (e) => PreparationArticleDto.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        <PreparationArticleDto>[];

    final timeline = PreparationTimelineDto.fromJson(json);

    return BonPreparationDto(
      id: json['id']?.toString() ?? json['idDoc']?.toString(),
      documentCode:
          json['code']?.toString() ??
          json['documentCode']?.toString() ??
          json['codeDoc']?.toString() ??
          json['numDoc']?.toString(),
      customerName:
          json['nomPrenomTier']?.toString() ??
          json['nomTier']?.toString() ??
          json['raisonSociale']?.toString() ??
          '',
      date:
          json['dateDocument']?.toString() ??
          json['dateCreation']?.toString() ??
          json['dateSaisie']?.toString(),
      status:
          json['libelleEtatDoc']?.toString() ??
          json['status']?.toString() ??
          '',
      statusColor:
          json['couleurEtatDoc']?.toString() ??
          json['statusColor']?.toString() ??
          '',
      amount: _toDouble(json['mntNetht']) ?? _toDouble(json['amount']),
      amountTTC: _toDouble(json['mntTtc']) ?? _toDouble(json['amountTTC']),
      amountTVA: _toDouble(json['mntTva']) ?? _toDouble(json['amountTVA']),
      reste: _toDouble(json['reste']) ?? 0.0,
      representative:
          json['nomPrenomRep']?.toString() ??
          json['RepDoc']?.toString() ??
          json['representative']?.toString() ??
          '',
      tier: json['idTier']?.toString() ?? json['codeTier']?.toString() ?? '',
      tierName: json['nomPrenomTier']?.toString(),
      deliveryAddress:
          json['adresseTier']?.toString() ??
          json['deliveryAddress']?.toString() ??
          '',
      phone: json['telTier']?.toString() ?? json['phone']?.toString() ?? '',
      documentType:
          json['libelleClasseDocument']?.toString() ??
          json['documentType']?.toString() ??
          json['titreImprimable']?.toString() ??
          '',
      documentTypeCode:
          json['codeClasseDocument']?.toString() ??
          json['documentTypeCode']?.toString() ??
          '',
      stationName:
          json['libelleStation']?.toString() ??
          json['stationName']?.toString() ??
          '',
      idStation: json['idStation']?.toString() ?? '',
      currency:
          json['symbole']?.toString() ?? json['codeDev']?.toString() ?? 'DT',
      articles: articlesDtos,
      timeline: timeline,
      codePiece: json['codePiece']?.toString(),
      preparedBy:
          json['preparedBy']?.toString() ?? json['nomPrenomRep']?.toString(),
      concretizedBy: json['concretizedBy']?.toString(),
      apporteur: json['apporteur']?.toString(),
      exchangeRate: _toDouble(json['exchangeRate']),
      affecterSur: json['affecterSur']?.toString(),
      clientRaisonSociale:
          json['clientRaisonSociale']?.toString() ??
          json['raisonSociale']?.toString(),
      clientTaxNumber:
          json['clientTaxNumber']?.toString() ??
          json['matriculeFiscale']?.toString(),
      clientAddress:
          json['clientAddress']?.toString() ?? json['adresseTier']?.toString(),
      clientPhone:
          json['clientPhone']?.toString() ?? json['telTier']?.toString(),
      clientContactPerson: json['clientContactPerson']?.toString(),
      clientCustomStatus: json['clientCustomStatus']?.toString(),
      idClassedocument:
          json['idClassedocument']?.toString() ??
          json['idClasseDocument']?.toString() ??
          json['codeClasseDocument']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentCode': documentCode,
    'customerName': customerName,
    'date': date,
    'status': status,
    'statusColor': statusColor,
    'amount': amount,
    'amountTTC': amountTTC,
    'amountTVA': amountTVA,
    'reste': reste,
    'representative': representative,
    'tier': tier,
    'tierName': tierName,
    'deliveryAddress': deliveryAddress,
    'phone': phone,
    'documentType': documentType,
    'documentTypeCode': documentTypeCode,
    'stationName': stationName,
    'idStation': idStation,
    'currency': currency,
    'articles': articles?.map((e) => e.toJson()).toList(),
    'timeline': timeline?.toJson(),
    'codePiece': codePiece,
    'preparedBy': preparedBy,
    'concretizedBy': concretizedBy,
    'apporteur': apporteur,
    'exchangeRate': exchangeRate,
    'affecterSur': affecterSur,
    'clientRaisonSociale': clientRaisonSociale,
    'clientTaxNumber': clientTaxNumber,
    'clientAddress': clientAddress,
    'clientPhone': clientPhone,
    'clientContactPerson': clientContactPerson,
    'clientCustomStatus': clientCustomStatus,
    'idClassedocument': idClassedocument,
  };
}
