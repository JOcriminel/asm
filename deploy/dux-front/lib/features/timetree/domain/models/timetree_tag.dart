class TimetreeTag {
  final String id;
  final String name;
  final String? color;

  const TimetreeTag({
    required this.id,
    required this.name,
    this.color,
  });

  factory TimetreeTag.fromJson(Map<String, dynamic> json) {
    return TimetreeTag(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'name': name,
      'color': color,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetreeTag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
