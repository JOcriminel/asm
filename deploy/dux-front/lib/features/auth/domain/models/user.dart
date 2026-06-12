class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String station;
  final String phone;
  final String tierId;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.station,
    required this.phone,
    required this.tierId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      station: json['station'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      tierId: json['tierId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'station': station,
      'phone': phone,
      'tierId': tierId,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
    String? station,
    String? phone,
    String? tierId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      station: station ?? this.station,
      phone: phone ?? this.phone,
      tierId: tierId ?? this.tierId,
    );
  }
}
