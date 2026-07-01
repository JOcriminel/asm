import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class TimetreePopupMenuDesign {
  final String backgroundColorHex;
  final String iconColorHex;
  final String textColorHex;
  final String iconName;
  final bool showCategories;
  final bool showPages;
  final bool showDashboard;

  const TimetreePopupMenuDesign({
    this.backgroundColorHex = '#FFFFFF',
    this.iconColorHex = '#000000',
    this.textColorHex = '#000000',
    this.iconName = 'more_vert',
    this.showCategories = true,
    this.showPages = true,
    this.showDashboard = true,
  });

  factory TimetreePopupMenuDesign.fromJson(Map<String, dynamic> json) {
    return TimetreePopupMenuDesign(
      backgroundColorHex: json['backgroundColorHex'] as String? ?? '#FFFFFF',
      iconColorHex: json['iconColorHex'] as String? ?? '#000000',
      textColorHex: json['textColorHex'] as String? ?? '#000000',
      iconName: json['iconName'] as String? ?? 'more_vert',
      showCategories: json['showCategories'] as bool? ?? true,
      showPages: json['showPages'] as bool? ?? true,
      showDashboard: json['showDashboard'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'backgroundColorHex': backgroundColorHex,
        'iconColorHex': iconColorHex,
        'textColorHex': textColorHex,
        'iconName': iconName,
        'showCategories': showCategories,
        'showPages': showPages,
        'showDashboard': showDashboard,
      };

  TimetreePopupMenuDesign copyWith({
    String? backgroundColorHex,
    String? iconColorHex,
    String? textColorHex,
    String? iconName,
    bool? showCategories,
    bool? showPages,
    bool? showDashboard,
  }) {
    return TimetreePopupMenuDesign(
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      iconColorHex: iconColorHex ?? this.iconColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      iconName: iconName ?? this.iconName,
      showCategories: showCategories ?? this.showCategories,
      showPages: showPages ?? this.showPages,
      showDashboard: showDashboard ?? this.showDashboard,
    );
  }
}

class TimetreePopupMenuDesignNotifier extends StateNotifier<TimetreePopupMenuDesign> {
  TimetreePopupMenuDesignNotifier(this._storage) : super(const TimetreePopupMenuDesign()) {
    _load();
  }

  final FlutterSecureStorage _storage;
  static const _key = 'timetree_popup_menu_design';

  Future<void> _load() async {
    try {
      final data = await _storage.read(key: _key);
      if (data != null) {
        state = TimetreePopupMenuDesign.fromJson(jsonDecode(data));
      }
    } catch (_) {}
  }

  Future<void> updateDesign(TimetreePopupMenuDesign design) async {
    state = design;
    try {
      await _storage.write(key: _key, value: jsonEncode(design.toJson()));
    } catch (_) {}
  }

  Future<void> reset() async {
    state = const TimetreePopupMenuDesign();
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

final timetreePopupMenuDesignProvider =
    StateNotifierProvider<TimetreePopupMenuDesignNotifier, TimetreePopupMenuDesign>((ref) {
  // Use secure storage
  return TimetreePopupMenuDesignNotifier(const FlutterSecureStorage());
});
