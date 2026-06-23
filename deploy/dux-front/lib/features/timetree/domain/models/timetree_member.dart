import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';

/// Clean domain model representing a TimeTree Member.
class TimetreeMember {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;

  const TimetreeMember({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory TimetreeMember.fromDto(TimetreeMemberDto dto) {
    return TimetreeMember(
      id: dto.id,
      username: dto.username,
      fullName: dto.fullName,
      email: dto.email,
      role: dto.role,
    );
  }

  TimetreeMember copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
  }) {
    return TimetreeMember(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  TimetreeMemberDto toDto() {
    return TimetreeMemberDto(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      role: role,
    );
  }

  @override
  String toString() => 'TimetreeMember(id: $id, fullName: $fullName, role: $role)';
}
