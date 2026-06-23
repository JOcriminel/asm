import 'package:dux_front/features/timetree/data/dto/timetree_permission_dto.dart';

class TimetreeCategoryPermission {
  final String categoryId;
  final String categoryName;
  final List<String> groupIds;

  const TimetreeCategoryPermission({
    required this.categoryId,
    required this.categoryName,
    required this.groupIds,
  });

  factory TimetreeCategoryPermission.fromDto(TimetreeCategoryPermissionDto dto) {
    return TimetreeCategoryPermission(
      categoryId: dto.categoryId,
      categoryName: dto.categoryName,
      groupIds: dto.groupIds,
    );
  }

  TimetreeCategoryPermission copyWith({
    String? categoryId,
    String? categoryName,
    List<String>? groupIds,
  }) {
    return TimetreeCategoryPermission(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}

class TimetreePagePermission {
  final String pageId;
  final String pageName;
  final List<String> groupIds;

  const TimetreePagePermission({
    required this.pageId,
    required this.pageName,
    required this.groupIds,
  });

  factory TimetreePagePermission.fromDto(TimetreePagePermissionDto dto) {
    return TimetreePagePermission(
      pageId: dto.pageId,
      pageName: dto.pageName,
      groupIds: dto.groupIds,
    );
  }

  TimetreePagePermission copyWith({
    String? pageId,
    String? pageName,
    List<String>? groupIds,
  }) {
    return TimetreePagePermission(
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}

class TimetreePermissionMatrix {
  final List<TimetreeCategoryPermission> categories;
  final List<TimetreePagePermission> pages;

  const TimetreePermissionMatrix({
    required this.categories,
    required this.pages,
  });

  factory TimetreePermissionMatrix.fromDto(TimetreePermissionMatrixDto dto) {
    return TimetreePermissionMatrix(
      categories: dto.categories.map(TimetreeCategoryPermission.fromDto).toList(),
      pages: dto.pages.map(TimetreePagePermission.fromDto).toList(),
    );
  }
}
