import 'package:dux_front/features/timetree/data/dto/timetree_role_dto.dart';

/// Clean domain model representing a TimeTree Role.
class TimetreeRole {
  final String code;
  final String name;

  const TimetreeRole({
    required this.code,
    required this.name,
  });

  factory TimetreeRole.fromDto(TimetreeRoleDto dto) {
    return TimetreeRole(
      code: dto.code,
      name: dto.name,
    );
  }

  @override
  String toString() => 'TimetreeRole(code: $code, name: $name)';
}
