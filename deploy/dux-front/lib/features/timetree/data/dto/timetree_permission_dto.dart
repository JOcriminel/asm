class TimetreeCategoryPermissionDto {
  final String categoryId;
  final String categoryName;
  final List<String> groupIds;

  const TimetreeCategoryPermissionDto({
    required this.categoryId,
    required this.categoryName,
    required this.groupIds,
  });

  factory TimetreeCategoryPermissionDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCategoryPermissionDto(
      categoryId: (json['categoryId'] ?? '').toString(),
      categoryName: json['categoryName'] as String? ?? '',
      groupIds: (json['groupIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class TimetreePagePermissionDto {
  final String pageId;
  final String pageName;
  final List<String> groupIds;

  const TimetreePagePermissionDto({
    required this.pageId,
    required this.pageName,
    required this.groupIds,
  });

  factory TimetreePagePermissionDto.fromJson(Map<String, dynamic> json) {
    return TimetreePagePermissionDto(
      pageId: (json['pageId'] ?? '').toString(),
      pageName: json['pageName'] as String? ?? '',
      groupIds: (json['groupIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class TimetreePermissionMatrixDto {
  final List<TimetreeCategoryPermissionDto> categories;
  final List<TimetreePagePermissionDto> pages;

  const TimetreePermissionMatrixDto({
    required this.categories,
    required this.pages,
  });

  factory TimetreePermissionMatrixDto.fromJson(Map<String, dynamic> json) {
    return TimetreePermissionMatrixDto(
      categories: (json['categories'] as List?)
              ?.map((e) => TimetreeCategoryPermissionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pages: (json['pages'] as List?)
              ?.map((e) => TimetreePagePermissionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
