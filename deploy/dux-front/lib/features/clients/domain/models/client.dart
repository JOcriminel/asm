class Client {
  final String id;
  final String code;
  final String nomPrenom;
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
  final int? nbDoc;
  final DateTime? dateCreation;

  const Client({
    required this.id,
    required this.code,
    required this.nomPrenom,
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
}
