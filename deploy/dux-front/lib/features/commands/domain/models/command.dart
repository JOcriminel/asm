import '../../../../core/models/base_document.dart';

class ArticleItem {
  final String id;
  final String code;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? unite;
  final double? discountPercent;
  final double? netHT;
  final double? tvaPercent;
  final double? puTTC;
  final double? totalTTC;
  final String? stock;
  final List<String> serialNumbers;
  final Map<String, dynamic>? rawJson;
  final String? numSerie;
  final String? familyId;
  final String? familyName;

  double get total => quantity * unitPrice;

  bool get hasSerialNumbers {
    if (numSerie == null) return false;
    final s = numSerie!.trim().toLowerCase();
    return s == '1' || s == '1.0' || s == 'true' || s == 'oui' || s == 'o' || s == 'yes' || s == 'y';
  }

  const ArticleItem({
    required this.id,
    required this.code,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.unite,
    this.discountPercent,
    this.netHT,
    this.tvaPercent,
    this.puTTC,
    this.totalTTC,
    this.stock,
    this.serialNumbers = const [],
    this.rawJson,
    this.numSerie,
    this.familyId,
    this.familyName,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num? ?? 0.0).toDouble(),
      unite: json['unite'] as String?,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      netHT: (json['netHT'] as num?)?.toDouble(),
      tvaPercent: (json['tvaPercent'] as num?)?.toDouble(),
      puTTC: (json['puTTC'] as num?)?.toDouble(),
      totalTTC: (json['totalTTC'] as num?)?.toDouble(),
      stock: json['stock'] as String?,
      serialNumbers: json['serialNumbers'] != null
          ? List<String>.from(json['serialNumbers'])
          : const [],
      rawJson: json['rawJson'] as Map<String, dynamic>?,
      numSerie: json['numSerie']?.toString(),
      familyId: json['familyId']?.toString(),
      familyName: json['familyName']?.toString(),
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

  ArticleItem copyWith({
    String? id,
    String? code,
    String? name,
    int? quantity,
    double? unitPrice,
    String? unite,
    double? discountPercent,
    double? netHT,
    double? tvaPercent,
    double? puTTC,
    double? totalTTC,
    String? stock,
    List<String>? serialNumbers,
    Map<String, dynamic>? rawJson,
    String? numSerie,
    String? familyId,
    String? familyName,
  }) {
    return ArticleItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unite: unite ?? this.unite,
      discountPercent: discountPercent ?? this.discountPercent,
      netHT: netHT ?? this.netHT,
      tvaPercent: tvaPercent ?? this.tvaPercent,
      puTTC: puTTC ?? this.puTTC,
      totalTTC: totalTTC ?? this.totalTTC,
      stock: stock ?? this.stock,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      rawJson: rawJson ?? this.rawJson,
      numSerie: numSerie ?? this.numSerie,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
    );
  }
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

class Command implements BaseDocument {
  @override
  final String id;
  @override
  final String documentCode;     // e.g. "000005"
  @override
  final String documentType;     // e.g. "Bon de Commande Client"
  @override
  final String documentTypeCode; // e.g. "BCC"
  @override
  final String customerName;     // nomPrenomTier
  @override
  final DateTime date;           // dateDocument
  @override
  final String status;           // libelleEtatDoc
  @override
  final String statusColor;      // couleurEtatDoc (CSS color string)
  @override
  final double amount;           // mntNetht (HT)
  @override
  final double amountTTC;        // mntTtc
  @override
  final double amountTVA;        // mntTva
  @override
  final double reste;            // remaining amount
  @override
  final String representative;   // nomPrenomRep / RepDoc
  @override
  final String tier;             // idTier or codeTier
  @override
  final String deliveryAddress;  // adresseTier
  @override
  final String phone;            // telTier
  @override
  final String currency;         // symbole (e.g. "DT") or codeDev (e.g. "TND")
  @override
  final String stationName;      // libelleStation
  @override
  final String idStation;        // Station ID (e.g. "1")
  final List<ArticleItem> articles;
  final CommandTimeline timeline;
  final ClasseDocument? classeDocument;

  // New detailed fields
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
    // New fields
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
      // New fields
      codePiece: json['codePiece'] as String?,
      preparedBy: json['preparedBy'] as String?,
      concretizedBy: json['concretizedBy'] as String?,
      apporteur: json['apporteur'] as String?,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      affecterSur: json['affecterSur'] as String?,
      clientRaisonSociale: json['clientRaisonSociale'] as String?,
      clientTaxNumber: json['clientTaxNumber'] as String?,
      clientAddress: json['clientAddress'] as String?,
      clientPhone: json['clientPhone'] as String?,
      clientContactPerson: json['clientContactPerson'] as String?,
      clientCustomStatus: json['clientCustomStatus'] as String?,
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
        // New fields
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
      };

  Command copyWith({
    String? id,
    String? documentCode,
    String? documentType,
    String? documentTypeCode,
    String? customerName,
    DateTime? date,
    String? status,
    String? statusColor,
    double? amount,
    double? amountTTC,
    double? amountTVA,
    double? reste,
    String? representative,
    String? tier,
    String? deliveryAddress,
    String? phone,
    String? currency,
    String? stationName,
    String? idStation,
    List<ArticleItem>? articles,
    CommandTimeline? timeline,
    ClasseDocument? classeDocument,
    String? codePiece,
    String? preparedBy,
    String? concretizedBy,
    String? apporteur,
    double? exchangeRate,
    String? affecterSur,
    String? clientRaisonSociale,
    String? clientTaxNumber,
    String? clientAddress,
    String? clientPhone,
    String? clientContactPerson,
    String? clientCustomStatus,
  }) {
    return Command(
      id: id ?? this.id,
      documentCode: documentCode ?? this.documentCode,
      documentType: documentType ?? this.documentType,
      documentTypeCode: documentTypeCode ?? this.documentTypeCode,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      amount: amount ?? this.amount,
      amountTTC: amountTTC ?? this.amountTTC,
      amountTVA: amountTVA ?? this.amountTVA,
      reste: reste ?? this.reste,
      representative: representative ?? this.representative,
      tier: tier ?? this.tier,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      stationName: stationName ?? this.stationName,
      idStation: idStation ?? this.idStation,
      articles: articles ?? this.articles,
      timeline: timeline ?? this.timeline,
      classeDocument: classeDocument ?? this.classeDocument,
      codePiece: codePiece ?? this.codePiece,
      preparedBy: preparedBy ?? this.preparedBy,
      concretizedBy: concretizedBy ?? this.concretizedBy,
      apporteur: apporteur ?? this.apporteur,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      affecterSur: affecterSur ?? this.affecterSur,
      clientRaisonSociale: clientRaisonSociale ?? this.clientRaisonSociale,
      clientTaxNumber: clientTaxNumber ?? this.clientTaxNumber,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      clientContactPerson: clientContactPerson ?? this.clientContactPerson,
      clientCustomStatus: clientCustomStatus ?? this.clientCustomStatus,
    );
  }
}

enum CommandSortOrder {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  nameAsc,
  nameDesc,
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
  final CommandSortOrder sortOrder;

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
    this.sortOrder = CommandSortOrder.dateDesc,
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
    CommandSortOrder? sortOrder,
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
      sortOrder: sortOrder ?? this.sortOrder,
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
