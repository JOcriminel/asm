/// DTO representing the backend payload for a TimeTree Role.
class TimetreeRoleDto {
  final String code;
  final String name;

  const TimetreeRoleDto({
    required this.code,
    required this.name,
  });

  factory TimetreeRoleDto.fromJson(Map<String, dynamic> json) {
    return TimetreeRoleDto(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}
