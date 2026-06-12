class ArticleItem {
  final String id;
  final String code;
  final String name;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  const ArticleItem({
    required this.id,
    required this.code,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class CommandTimeline {
  final DateTime? created;
  final DateTime? validated;
  final DateTime? delivered;

  const CommandTimeline({this.created, this.validated, this.delivered});

  factory CommandTimeline.fromJson(Map<String, dynamic> json) {
    return CommandTimeline(
      created: json['created'] != null
          ? DateTime.tryParse((json['created'] as String).replaceFirst(' ', 'T'))
          : null,
      validated: json['validated'] != null
          ? DateTime.tryParse((json['validated'] as String).replaceFirst(' ', 'T'))
          : null,
      delivered: json['delivered'] != null
          ? DateTime.tryParse((json['delivered'] as String).replaceFirst(' ', 'T'))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'created': created?.toIso8601String(),
        'validated': validated?.toIso8601String(),
        'delivered': delivered?.toIso8601String(),
      };
}

class ClasseDocument {
  final String id;
  final int version;
  final String code;
  final String libelle;
  final String titre;
  final String titreImprimable;
  final bool affecteStock;
  final bool affecteSolde;
  final bool affectecmp;
  final bool isInput;
  final bool isOutput;
  final String idTypeCalcul;
  final bool isAchat;
  final bool isVente;
  final bool useMainStationRegime;
  final String prefixe;
  final int numAtteint;
  final bool isTvaConsider;
  final bool isReglable;
  final bool isFacturable;
  final bool useDestination;
  final bool isFacture;
  final bool isAvoir;
  final bool isRepDachat;
  final bool transformable;
  final String couleur;

  const ClasseDocument({
    required this.id,
    this.version = 0,
    required this.code,
    required this.libelle,
    this.titre = '',
    this.titreImprimable = '',
    this.affecteStock = false,
    this.affecteSolde = false,
    this.affectecmp = false,
    this.isInput = false,
    this.isOutput = false,
    this.idTypeCalcul = '',
    this.isAchat = false,
    required this.isVente,
    this.useMainStationRegime = false,
    this.prefixe = '',
    this.numAtteint = 0,
    this.isTvaConsider = true,
    this.isReglable = true,
    this.isFacturable = false,
    this.useDestination = false,
    this.isFacture = false,
    this.isAvoir = false,
    this.isRepDachat = false,
    this.transformable = true,
    this.couleur = '',
  });

  factory ClasseDocument.fromJson(Map<String, dynamic> json) {
    return ClasseDocument(
      id: json['id']?.toString() ?? '',
      version: json['version'] as int? ?? 0,
      code: json['code']?.toString() ?? '',
      libelle: json['libelle']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      titreImprimable: json['titreImprimable']?.toString() ?? '',
      affecteStock: json['affecteStock'] as bool? ?? false,
      affecteSolde: json['affecteSolde'] as bool? ?? false,
      affectecmp: json['affectecmp'] as bool? ?? false,
      isInput: json['isInput'] as bool? ?? false,
      isOutput: json['isOutput'] as bool? ?? false,
      idTypeCalcul: json['idTypeCalcul']?.toString() ?? '',
      isAchat: json['isAchat'] as bool? ?? false,
      isVente: json['isVente'] as bool? ?? false,
      useMainStationRegime: json['useMainStationRegime'] as bool? ?? false,
      prefixe: json['prefixe']?.toString() ?? '',
      numAtteint: json['numAtteint'] as int? ?? 0,
      isTvaConsider: json['isTvaConsider'] as bool? ?? true,
      isReglable: json['isReglable'] as bool? ?? true,
      isFacturable: json['isFacturable'] as bool? ?? false,
      useDestination: json['useDestination'] as bool? ?? false,
      isFacture: json['isFacture'] as bool? ?? false,
      isAvoir: json['isAvoir'] as bool? ?? false,
      isRepDachat: json['isRep_Dachat'] as bool? ?? false,
      transformable: json['transformable'] as bool? ?? true,
      couleur: json['couleur']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'code': code,
        'libelle': libelle,
        'titre': titre,
        'titreImprimable': titreImprimable,
        'affecteStock': affecteStock,
        'affecteSolde': affecteSolde,
        'affectecmp': affectecmp,
        'isInput': isInput,
        'isOutput': isOutput,
        'idTypeCalcul': idTypeCalcul,
        'isAchat': isAchat,
        'isVente': isVente,
        'useMainStationRegime': useMainStationRegime,
        'prefixe': prefixe,
        'numAtteint': numAtteint,
        'isTvaConsider': isTvaConsider,
        'isReglable': isReglable,
        'isFacturable': isFacturable,
        'useDestination': useDestination,
        'isFacture': isFacture,
        'isAvoir': isAvoir,
        'isRep_Dachat': isRepDachat,
        'transformable': transformable,
        'couleur': couleur,
      };
}

class Command {
  final String id;
  final String documentCode;     // e.g. "000005"
  final String documentType;     // e.g. "Bon de Commande Client"
  final String documentTypeCode; // e.g. "BCC"
  final String customerName;     // nomPrenomTier
  final DateTime date;           // dateDocument
  final String status;           // libelleEtatDoc
  final String statusColor;      // couleurEtatDoc (CSS color string)
  final double amount;           // mntNetht (HT)
  final double amountTTC;        // mntTtc
  final double amountTVA;        // mntTva
  final double reste;            // remaining amount
  final String representative;   // nomPrenomRep / RepDoc
  final String tier;             // idTier or codeTier
  final String deliveryAddress;  // adresseTier
  final String phone;            // telTier
  final String currency;         // symbole (e.g. "DT") or codeDev (e.g. "TND")
  final String stationName;      // libelleStation
  final String idStation;        // Station ID (e.g. "1")
  final List<ArticleItem> articles;
  final CommandTimeline timeline;
  final ClasseDocument? classeDocument;

  // Computed
  double get totalHT => amount;
  double get vat => amountTVA > 0 ? amountTVA : amount * 0.19;
  double get totalTTC => amountTTC > 0 ? amountTTC : amount + vat;

  const Command({
    required this.id,
    required this.documentCode,
    this.documentType = '',
    this.documentTypeCode = '',
    required this.customerName,
    required this.date,
    required this.status,
    this.statusColor = '',
    required this.amount,
    this.amountTTC = 0.0,
    this.amountTVA = 0.0,
    this.reste = 0.0,
    required this.representative,
    required this.tier,
    required this.deliveryAddress,
    this.phone = '',
    this.currency = 'DT',
    this.stationName = '',
    this.idStation = '',
    required this.articles,
    required this.timeline,
    this.classeDocument,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      id: json['id'] as String? ?? '',
      documentCode: json['documentCode'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      documentTypeCode: json['documentTypeCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      amountTTC: (json['amountTTC'] as num? ?? 0.0).toDouble(),
      amountTVA: (json['amountTVA'] as num? ?? 0.0).toDouble(),
      reste: (json['reste'] as num? ?? 0.0).toDouble(),
      representative: json['representative'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currency: json['currency'] as String? ?? 'DT',
      stationName: json['stationName'] as String? ?? '',
      idStation: json['idStation'] as String? ?? '',
      articles: (json['articles'] as List<dynamic>?)
              ?.map((e) => ArticleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: json['timeline'] != null
          ? CommandTimeline.fromJson(json['timeline'] as Map<String, dynamic>)
          : const CommandTimeline(),
      classeDocument: json['classeDocument'] != null
          ? ClasseDocument.fromJson(json['classeDocument'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentCode': documentCode,
        'documentType': documentType,
        'documentTypeCode': documentTypeCode,
        'customerName': customerName,
        'date': date.toIso8601String(),
        'status': status,
        'statusColor': statusColor,
        'amount': amount,
        'amountTTC': amountTTC,
        'amountTVA': amountTVA,
        'reste': reste,
        'representative': representative,
        'tier': tier,
        'deliveryAddress': deliveryAddress,
        'phone': phone,
        'currency': currency,
        'stationName': stationName,
        'idStation': idStation,
        'articles': articles.map((e) => e.toJson()).toList(),
        'timeline': timeline.toJson(),
        'classeDocument': classeDocument?.toJson(),
      };
}

class CommandFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? tier;
  final String? representative;
  final String? documentCode;
  final String? status;
  final bool allDocuments;
  final String? articleFilter;
  final bool advancedFilterActive;

  const CommandFilter({
    this.dateFrom,
    this.dateTo,
    this.tier,
    this.representative,
    this.documentCode,
    this.status,
    this.allDocuments = false,
    this.articleFilter,
    this.advancedFilterActive = false,
  });

  CommandFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? tier,
    String? representative,
    String? documentCode,
    String? status,
    bool? allDocuments,
    String? articleFilter,
    bool? advancedFilterActive,
    bool clearDates = false,
  }) {
    return CommandFilter(
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      tier: tier ?? this.tier,
      representative: representative ?? this.representative,
      documentCode: documentCode ?? this.documentCode,
      status: status ?? this.status,
      allDocuments: allDocuments ?? this.allDocuments,
      articleFilter: articleFilter ?? this.articleFilter,
      advancedFilterActive: advancedFilterActive ?? this.advancedFilterActive,
    );
  }

  bool get isEmpty =>
      dateFrom == null &&
      dateTo == null &&
      (tier == null || tier!.isEmpty) &&
      (representative == null || representative!.isEmpty) &&
      (documentCode == null || documentCode!.isEmpty) &&
      (status == null || status!.isEmpty) &&
      (articleFilter == null || articleFilter!.isEmpty) &&
      allDocuments;
}
