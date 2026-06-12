class Station {
  final String id;
  final String name;
  final String code;
  final String address;
  final String region;
  final String phone;
  final String fax;
  final String email;
  final String managerName;
  final String typeStation;
  final String matriculeFiscal;
  final String logo;
  final String active;
  final String workingHours;
  final int capacity;
  final double latitude;
  final double longitude;

  const Station({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.region,
    required this.phone,
    required this.fax,
    required this.email,
    required this.managerName,
    required this.typeStation,
    required this.matriculeFiscal,
    required this.logo,
    required this.active,
    required this.workingHours,
    required this.capacity,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      region: json['region'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fax: json['fax'] as String? ?? '',
      email: json['email'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      typeStation: json['typeStation'] as String? ?? '',
      matriculeFiscal: json['matriculeFiscal'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      active: json['active'] as String? ?? '',
      workingHours: json['workingHours'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
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
