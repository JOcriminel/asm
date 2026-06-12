// ─── Safe numeric helpers ──────────────────────────────────────────────────

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
  return int.tryParse(v.toString().trim());
}

// ─── Article line item ─────────────────────────────────────────────────────

class ArticleItemDto {
  final String? id;
  final String? code;
  final String? name;
  final int? quantity;
  final double? unitPrice;

  ArticleItemDto({this.id, this.code, this.name, this.quantity, this.unitPrice});

  factory ArticleItemDto.fromJson(Map<String, dynamic> json) {
    return ArticleItemDto(
      id: json['id']?.toString() ?? json['idArticle']?.toString(),
      code: json['code']?.toString() ??
          json['codeArticle']?.toString() ??
          json['ref']?.toString(),
      name: json['name']?.toString() ??
          json['libelle']?.toString() ??
          json['designation']?.toString() ??
          json['libArticle']?.toString(),
      quantity: _toInt(json['quantity']) ??
          _toInt(json['qte']) ??
          _toInt(json['quantite']),
      unitPrice: _toDouble(json['unitPrice']) ??
          _toDouble(json['prix']) ??
          _toDouble(json['pu']) ??
          _toDouble(json['prixUnitaire']),
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

// ─── Timeline ──────────────────────────────────────────────────────────────

class CommandTimelineDto {
  final String? created;
  final String? validated;
  final String? delivered;

  CommandTimelineDto({this.created, this.validated, this.delivered});

  factory CommandTimelineDto.fromJson(Map<String, dynamic> json) {
    return CommandTimelineDto(
      created: json['created']?.toString() ??
          json['dateCreation']?.toString() ??
          json['dateSaisie']?.toString() ??
          json['dateDocument']?.toString(),
      validated: json['validated']?.toString() ??
          json['dateValidation']?.toString(),
      delivered: json['delivered']?.toString() ??
          json['dateLivraison']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'created': created,
        'validated': validated,
        'delivered': delivered,
      };
}

// ─── Main command DTO ──────────────────────────────────────────────────────

class ClasseDocumentDto {
  final String? id;
  final int? version;
  final String? code;
  final String? libelle;
  final String? titre;
  final String? titreImprimable;
  final bool? affecteStock;
  final bool? affecteSolde;
  final bool? affectecmp;
  final bool? isInput;
  final bool? isOutput;
  final String? idTypeCalcul;
  final bool? isAchat;
  final bool? isVente;
  final bool? useMainStationRegime;
  final String? prefixe;
  final int? numAtteint;
  final bool? isTvaConsider;
  final bool? isReglable;
  final bool? isFacturable;
  final bool? useDestination;
  final bool? isFacture;
  final bool? isAvoir;
  final bool? isRepDachat;
  final bool? transformable;
  final String? couleur;

  ClasseDocumentDto({
    this.id,
    this.version,
    this.code,
    this.libelle,
    this.titre,
    this.titreImprimable,
    this.affecteStock,
    this.affecteSolde,
    this.affectecmp,
    this.isInput,
    this.isOutput,
    this.idTypeCalcul,
    this.isAchat,
    this.isVente,
    this.useMainStationRegime,
    this.prefixe,
    this.numAtteint,
    this.isTvaConsider,
    this.isReglable,
    this.isFacturable,
    this.useDestination,
    this.isFacture,
    this.isAvoir,
    this.isRepDachat,
    this.transformable,
    this.couleur,
  });

  factory ClasseDocumentDto.fromJson(Map<String, dynamic> json) {
    return ClasseDocumentDto(
      id: json['id']?.toString(),
      version: _toInt(json['version']),
      code: json['code']?.toString(),
      libelle: json['libelle']?.toString(),
      titre: json['titre']?.toString(),
      titreImprimable: json['titreImprimable']?.toString(),
      affecteStock: json['affecteStock'] as bool?,
      affecteSolde: json['affecteSolde'] as bool?,
      affectecmp: json['affectecmp'] as bool?,
      isInput: json['isInput'] as bool?,
      isOutput: json['isOutput'] as bool?,
      idTypeCalcul: json['idTypeCalcul']?.toString(),
      isAchat: json['isAchat'] as bool?,
      isVente: json['isVente'] as bool?,
      useMainStationRegime: json['useMainStationRegime'] as bool?,
      prefixe: json['prefixe']?.toString(),
      numAtteint: _toInt(json['numAtteint']),
      isTvaConsider: json['isTvaConsider'] as bool?,
      isReglable: json['isReglable'] as bool?,
      isFacturable: json['isFacturable'] as bool?,
      useDestination: json['useDestination'] as bool?,
      isFacture: json['isFacture'] as bool?,
      isAvoir: json['isAvoir'] as bool?,
      isRepDachat: json['isRep_Dachat'] as bool?,
      transformable: json['transformable'] as bool?,
      couleur: json['couleur']?.toString(),
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

class CommandDto {
  final String? id;
  final String? documentCode;    // code / codeDoc
  final String? customerName;   // nomPrenomTier
  final String? date;           // dateDocument
  final String? status;         // libelleEtatDoc
  final String? statusColor;    // couleurEtatDoc
  final double? amount;         // mntNetht (HT)
  final double? amountTTC;      // mntTtc
  final double? amountTVA;      // mntTva
  final double? reste;          // reste (remaining)
  final String? representative; // nomPrenomRep / RepDoc
  final String? tier;           // idTier / codeTier
  final String? tierName;       // nomPrenomTier (used as customerName)
  final String? deliveryAddress; // adresseTier
  final String? phone;          // telTier
  final String? documentType;   // libelleClasseDocument / titreImprimable
  final String? documentTypeCode; // codeClasseDocument
  final String? stationName;    // libelleStation
  final String? idStation;      // idStation
  final String? currency;       // codeDev / symbole
  final bool? isVente;          // isVente
  final List<ArticleItemDto>? articles;
  final CommandTimelineDto? timeline;
  final ClasseDocumentDto? classeDocument;

  CommandDto({
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
    this.isVente,
    this.articles,
    this.timeline,
    this.classeDocument,
  });

  factory CommandDto.fromJson(Map<String, dynamic> json) {
    // Article lines — not included in list response, only in detail response
    final rawArticles = json['articles'] as List? ??
        json['lignes'] as List? ??
        json['details'] as List? ??
        json['lignesDoc'] as List?;

    final articlesDtos = rawArticles
            ?.map((e) => ArticleItemDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ArticleItemDto>[];

    // Build timeline from top-level date fields (list response has no nested timeline)
    final timeline = CommandTimelineDto(
      created: json['dateDocument']?.toString() ??
          json['dateCreation']?.toString() ??
          json['dateSaisie']?.toString(),
      validated: json['dateValidation']?.toString(),
      delivered: json['dateLivraison']?.toString(),
    );

    return CommandDto(
      // ── Identity ──────────────────────────────────────────
      id: json['id']?.toString() ??
          json['idDoc']?.toString(),

      // ── Document code ─────────────────────────────────────
      // The DUX API uses "code" for the document number (e.g. "000005")
      documentCode: json['code']?.toString() ??
          json['documentCode']?.toString() ??
          json['codeDoc']?.toString() ??
          json['numDoc']?.toString(),

      // ── Customer ──────────────────────────────────────────
      // DUX list response uses nomPrenomTier
      customerName: json['nomPrenomTier']?.toString() ??
          json['customerName']?.toString() ??
          json['client']?.toString() ??
          json['raisonSociale']?.toString() ??
          json['libTier']?.toString(),

      // ── Date ──────────────────────────────────────────────
      // DUX list response uses dateDocument
      date: json['dateDocument']?.toString() ??
          json['date']?.toString() ??
          json['dateDoc']?.toString() ??
          json['dateCreation']?.toString(),

      // ── Status ────────────────────────────────────────────
      // DUX list response uses libelleEtatDoc
      status: json['libelleEtatDoc']?.toString() ??
          json['status']?.toString() ??
          json['etat']?.toString() ??
          json['idEtat']?.toString(),

      // Status badge color from the API (e.g. "rgba(15, 11, 238, 1.00)")
      statusColor: json['couleurEtatDoc']?.toString(),

      // ── Amounts ───────────────────────────────────────────
      // DUX returns mntNetht (net HT), mntTtc (TTC), mntTva (TVA)
      amount: _toDouble(json['mntNetht']) ??
          _toDouble(json['amount']) ??
          _toDouble(json['totalHT']) ??
          _toDouble(json['montant']) ??
          _toDouble(json['mntht']),

      amountTTC: _toDouble(json['mntTtc']) ??
          _toDouble(json['montantTTC']) ??
          _toDouble(json['totalTTC']),

      amountTVA: _toDouble(json['mntTva']),

      reste: _toDouble(json['reste']),

      // ── Representative ────────────────────────────────────
      // DUX uses nomPrenomRep for the salesperson name
      representative: json['nomPrenomRep']?.toString() ??
          json['RepDoc']?.toString() ??
          json['representative']?.toString() ??
          json['repres']?.toString(),

      // ── Tier (client) ─────────────────────────────────────
      tier: json['idTier']?.toString() ??
          json['codeTier']?.toString() ??
          json['tier']?.toString(),

      tierName: json['nomPrenomTier']?.toString(),

      // ── Address / contact ─────────────────────────────────
      deliveryAddress: json['adresseTier']?.toString() ??
          json['deliveryAddress']?.toString() ??
          json['adresseLivraison']?.toString(),

      phone: json['telTier']?.toString(),

      // ── Document type ─────────────────────────────────────
      // e.g. "Bon de Commande Client", code "BCC"
      documentType: json['libelleClasseDocument']?.toString() ??
          json['titreImprimable']?.toString() ??
          json['documentType']?.toString(),

      documentTypeCode: json['codeClasseDocument']?.toString(),

      // ── Station ───────────────────────────────────────────
      stationName: json['libelleStation']?.toString(),
      idStation: json['idStation']?.toString(),

      // ── Currency ──────────────────────────────────────────
      // symbole: "DT", codeDev: "TND"
      currency: json['symbole']?.toString() ??
          json['codeDev']?.toString(),

      isVente: json['isVente'] as bool?,

      articles: articlesDtos,
      timeline: timeline,
      classeDocument: json['classeDocument'] != null
          ? ClasseDocumentDto.fromJson(json['classeDocument'] as Map<String, dynamic>)
          : null,
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
        'deliveryAddress': deliveryAddress,
        'phone': phone,
        'documentType': documentType,
        'documentTypeCode': documentTypeCode,
        'stationName': stationName,
        'idStation': idStation,
        'currency': currency,
        'isVente': isVente,
        'articles': articles?.map((e) => e.toJson()).toList(),
        'timeline': timeline?.toJson(),
        'classeDocument': classeDocument?.toJson(),
      };
}
