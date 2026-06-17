class ClientDto {
  final String? id;
  final String? code;
  final String? nomPrenom;
  final String? nomPrenomEdit;
  final String? tel;
  final String? mail;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? matriculeFiscal;
  final String? secteur;
  final String? stationLibelle;
  final String? devise;
  final dynamic nbDoc;
  final String? dateCreation;

  const ClientDto({
    this.id,
    this.code,
    this.nomPrenom,
    this.nomPrenomEdit,
    this.tel,
    this.mail,
    this.adresse,
    this.ville,
    this.pays,
    this.matriculeFiscal,
    this.secteur,
    this.stationLibelle,
    this.devise,
    this.nbDoc,
    this.dateCreation,
  });

  factory ClientDto.fromJson(Map<String, dynamic> json) {
    return ClientDto(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      nomPrenom: json['nomPrenom']?.toString(),
      nomPrenomEdit: json['nomPrenomEdit']?.toString(),
      tel: json['tel']?.toString(),
      mail: json['mail']?.toString(),
      adresse: json['adresse']?.toString(),
      ville: json['ville']?.toString(),
      pays: json['pays']?.toString(),
      matriculeFiscal: json['matriculeFiscal']?.toString(),
      secteur: json['secteur']?.toString(),
      stationLibelle: json['stationLibelle']?.toString(),
      devise: json['devise']?.toString(),
      nbDoc: json['nbDoc'],
      dateCreation: json['dateCreation']?.toString(),
    );
  }
}
