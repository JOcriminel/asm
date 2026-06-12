class Profile {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String station;
  final String phone;
  final String location;
  final String employeeId;
  final DateTime joinedDate;
  final String cellule;
  final String createur;
  final bool isActive;
  final bool isSuperAdmin;
  final String motDePasse;

  const Profile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.station,
    required this.phone,
    required this.location,
    required this.employeeId,
    required this.joinedDate,
    required this.cellule,
    required this.createur,
    required this.isActive,
    required this.isSuperAdmin,
    required this.motDePasse,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      station: json['station'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      joinedDate: DateTime.parse(json['joinedDate'] as String? ?? DateTime.now().toIso8601String()),
      cellule: json['cellule'] as String? ?? '',
      createur: json['createur'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      motDePasse: json['motDePasse'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'station': station,
      'phone': phone,
      'location': location,
      'employeeId': employeeId,
      'joinedDate': joinedDate.toIso8601String(),
      'cellule': cellule,
      'createur': createur,
      'isActive': isActive,
      'isSuperAdmin': isSuperAdmin,
      'motDePasse': motDePasse,
    };
  }

  Profile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? role,
    String? station,
    String? phone,
    String? location,
    String? employeeId,
    DateTime? joinedDate,
    String? cellule,
    String? createur,
    bool? isActive,
    bool? isSuperAdmin,
    String? motDePasse,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      station: station ?? this.station,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      employeeId: employeeId ?? this.employeeId,
      joinedDate: joinedDate ?? this.joinedDate,
      cellule: cellule ?? this.cellule,
      createur: createur ?? this.createur,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      motDePasse: motDePasse ?? this.motDePasse,
    );
  }
}
