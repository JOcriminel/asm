class StationDto {
  final String? id;
  final String? name;
  final String? code;
  final String? address;
  final String? region;
  final String? phone;
  final String? fax;
  final String? email;
  final String? managerName;
  final String? typeStation;
  final String? matriculeFiscal;
  final String? logo;
  final String? active;
  final String? workingHours;
  final int? capacity;
  final double? latitude;
  final double? longitude;

  StationDto({
    this.id,
    this.name,
    this.code,
    this.address,
    this.region,
    this.phone,
    this.fax,
    this.email,
    this.managerName,
    this.typeStation,
    this.matriculeFiscal,
    this.logo,
    this.active,
    this.workingHours,
    this.capacity,
    this.latitude,
    this.longitude,
  });

  // Safe int parser — handles both real JSON numbers and string-encoded integers
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  // Safe double parser — handles both real JSON numbers AND strings like ".0000000000"
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  factory StationDto.fromJson(Map<String, dynamic> json) {
    // Some APIs wrap the object under key "0"
    final Map<String, dynamic> data =
        (json['0'] is Map<String, dynamic>) ? json['0'] as Map<String, dynamic> : json;

    return StationDto(
      id: data['id']?.toString() ?? data['stationId']?.toString(),
      name: data['libelle']?.toString() ?? data['name']?.toString(),
      code: data['code']?.toString() ??
          data['codeStation']?.toString() ??
          data['id']?.toString(),
      address: data['adresse']?.toString() ?? data['address']?.toString(),
      region: data['ville']?.toString() ??
          data['region']?.toString() ??
          data['idRegion']?.toString(),
      phone: data['tel']?.toString() ?? data['phone']?.toString(),
      fax: data['fax']?.toString(),
      email: data['mail']?.toString() ?? data['email']?.toString(),
      managerName: data['responsable']?.toString() ??
          data['managerName']?.toString() ??
          data['libelleResponsable']?.toString(),
      typeStation: data['libelleTypeStation']?.toString(),
      matriculeFiscal: data['matfiscal']?.toString(),
      logo: data['logo']?.toString(),
      active: data['active']?.toString(),
      workingHours:
          data['horaires']?.toString() ?? data['workingHours']?.toString(),
      // API returns these as strings (e.g. ".0000000000") — use safe parsers
      capacity: _toInt(data['capacity']) ?? _toInt(data['capacite']),
      latitude: _toDouble(data['latitude']) ??
          _toDouble(data['lat']) ??
          _toDouble(data['Longueur']),
      longitude: _toDouble(data['longitude']) ??
          _toDouble(data['lng']) ??
          _toDouble(data['Hauteur']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'region': region,
      'phone': phone,
      'fax': fax,
      'email': email,
      'managerName': managerName,
      'typeStation': typeStation,
      'matriculeFiscal': matriculeFiscal,
      'logo': logo,
      'active': active,
      'workingHours': workingHours,
      'capacity': capacity,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
