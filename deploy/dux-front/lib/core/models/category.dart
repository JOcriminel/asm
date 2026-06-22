class Category {
  final String name;
  final bool active;

  Category({
    required this.name,
    this.active = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': active,
      };

  Category copyWith({
    String? name,
    bool? active,
  }) {
    return Category(
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}
