import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';

/// Clean domain model representing a TimeTree Member.
class TimetreeMember {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final bool canCreateAgendas;
  final bool canAddMembers;
  final String? profilePicture;

  const TimetreeMember({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.canCreateAgendas = true,
    this.canAddMembers = true,
    this.profilePicture,
  });

  factory TimetreeMember.fromDto(TimetreeMemberDto dto) {
    return TimetreeMember(
      id: dto.id,
      username: dto.username,
      fullName: dto.fullName,
      email: dto.email,
      role: dto.role,
      canCreateAgendas: dto.canCreateAgendas,
      canAddMembers: dto.canAddMembers,
      profilePicture: dto.profilePicture,
    );
  }

  TimetreeMember copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
    bool? canCreateAgendas,
    bool? canAddMembers,
    String? profilePicture,
  }) {
    return TimetreeMember(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      canCreateAgendas: canCreateAgendas ?? this.canCreateAgendas,
      canAddMembers: canAddMembers ?? this.canAddMembers,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  TimetreeMemberDto toDto() {
    return TimetreeMemberDto(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      role: role,
      canCreateAgendas: canCreateAgendas,
      canAddMembers: canAddMembers,
      profilePicture: profilePicture,
    );
  }

  @override
  String toString() => 'TimetreeMember(id: $id, fullName: $fullName, role: $role, canCreateAgendas: $canCreateAgendas, canAddMembers: $canAddMembers, profilePicture: ${profilePicture != null ? "HAS_IMAGE" : "null"})';
}
