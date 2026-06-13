class PreparationArticle {
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

  double get total => quantity * unitPrice;
  bool get hasSerialNumbers => numSerie == '1';

  const PreparationArticle({
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
    required this.serialNumbers,
    this.rawJson,
    this.numSerie,
  });

  PreparationArticle copyWith({
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
  }) {
    return PreparationArticle(
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
    );
  }
}

class PreparationTimeline {
  final DateTime? created;
  final DateTime? validated;
  final DateTime? delivered;

  const PreparationTimeline({this.created, this.validated, this.delivered});
}

class BonPreparation {
  final String id;
  final String documentCode;
  final String documentType;
  final String documentTypeCode;
  final String customerName;
  final DateTime date;
  final String status;
  final String statusColor;
  final double amount;
  final double amountTTC;
  final double amountTVA;
  final double reste;
  final String representative;
  final String tier;
  final String deliveryAddress;
  final String phone;
  final String currency;
  final String stationName;
  final String idStation;
  final List<PreparationArticle> articles;
  final PreparationTimeline timeline;

  // Detailed fields
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

  double get totalHT => amount;
  double get vat => amountTVA > 0 ? amountTVA : amount * 0.19;
  double get totalTTC => amountTTC > 0 ? amountTTC : amount + vat;

  const BonPreparation({
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

  BonPreparation copyWith({
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
    List<PreparationArticle>? articles,
    PreparationTimeline? timeline,
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
    String? idClassedocument,
  }) {
    return BonPreparation(
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
      idClassedocument: idClassedocument ?? this.idClassedocument,
    );
  }
}

class BonPreparationFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? tier;
  final String? representative;
  final String? documentCode;
  final String? status;
  final bool allDocuments;
  final String? articleFilter;
  final bool advancedFilterActive;

  const BonPreparationFilter({
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

  BonPreparationFilter copyWith({
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
    return BonPreparationFilter(
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
