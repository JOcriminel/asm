/// DTO representing the backend payload for a TimeTree Member.
class TimetreeMemberDto {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;

  const TimetreeMemberDto({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory TimetreeMemberDto.fromJson(Map<String, dynamic> json) {
    return TimetreeMemberDto(
      id: (json['id'] ?? '').toString(),
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
    };
  }
}
