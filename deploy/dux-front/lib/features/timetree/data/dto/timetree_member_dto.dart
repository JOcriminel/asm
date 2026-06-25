/// DTO representing the backend payload for a TimeTree Member.
class TimetreeMemberDto {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final bool canCreateAgendas;
  final bool canAddMembers;
  final String? profilePicture;

  const TimetreeMemberDto({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.canCreateAgendas = true,
    this.canAddMembers = true,
    this.profilePicture,
  });

  factory TimetreeMemberDto.fromJson(Map<String, dynamic> json) {
    return TimetreeMemberDto(
      id: (json['id'] ?? '').toString(),
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      canCreateAgendas: json['canCreateAgendas'] as bool? ?? true,
      canAddMembers: json['canAddMembers'] as bool? ?? true,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'canCreateAgendas': canCreateAgendas,
      'canAddMembers': canAddMembers,
      'profilePicture': profilePicture,
    };
  }
}
