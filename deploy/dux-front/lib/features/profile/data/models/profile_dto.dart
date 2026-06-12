class ProfileDto {
  final String? code;
  final String? nomEtPrenom;
  final String? login;
  final String? motDePasse;
  final String? telephone;
  final String? mail;
  final String? typeUtilisateur;
  final String? station;
  final String? cellule;
  final String? createur;
  final String? dateCreation;
  final String? active;
  final String? superAdmin;

  ProfileDto({
    this.code,
    this.nomEtPrenom,
    this.login,
    this.motDePasse,
    this.telephone,
    this.mail,
    this.typeUtilisateur,
    this.station,
    this.cellule,
    this.createur,
    this.dateCreation,
    this.active,
    this.superAdmin,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['0'] is Map<String, dynamic>)
        ? json['0'] as Map<String, dynamic>
        : json;

    final typeUser = data['typeUser'] as Map<String, dynamic>?;
    final typeUserLibelle = typeUser?['libelle']?.toString();

    return ProfileDto(
      code: data['code']?.toString() ?? data['Code']?.toString(),
      nomEtPrenom: data['nomPrenom']?.toString() ?? data['Nom et prénom']?.toString() ?? data['fullName']?.toString(),
      login: data['login']?.toString() ?? data['Login']?.toString() ?? data['username']?.toString(),
      motDePasse: data['motDePasse']?.toString() ?? data['Mot de passe']?.toString() ?? data['password']?.toString(),
      telephone: data['tel']?.toString() ?? data['Téléphone']?.toString() ?? data['telephone']?.toString() ?? data['phone']?.toString(),
      mail: data['mail']?.toString() ?? data['Mail']?.toString() ?? data['email']?.toString(),
      typeUtilisateur: typeUserLibelle ?? data['typeUtilisateur']?.toString() ?? data['Type Utilisateur']?.toString() ?? data['role']?.toString(),
      station: data['idStation']?.toString() ?? data['station']?.toString() ?? data['Station']?.toString(),
      cellule: data['libelle']?.toString() ?? data['cellule']?.toString() ?? data['Cellule']?.toString(),
      createur: data['createur']?.toString() ?? data['Créateur']?.toString(),
      dateCreation: data['dateCreation']?.toString() ?? data['Date création']?.toString(),
      active: data['active']?.toString(),
      superAdmin: typeUser?['superAdministrateur']?.toString() ?? data['superAdmin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'nomEtPrenom': nomEtPrenom,
      'login': login,
      'motDePasse': motDePasse,
      'telephone': telephone,
      'mail': mail,
      'typeUtilisateur': typeUtilisateur,
      'station': station,
      'cellule': cellule,
      'createur': createur,
      'dateCreation': dateCreation,
      'active': active,
      'superAdmin': superAdmin,
    };
  }
}
