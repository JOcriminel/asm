class ScreenConfig {
  final String documentType;
  final String pageTitle;
  final String searchHint;
  final bool enableBarcodeScanner;
  final bool enablePdfPrinting;
  final bool enableSerialNumberTracking;
  final List<String> visibleRoles;
  final String detailPageTitle;
  final bool hidePricesForOperateurs;
  final List<String> allowedRolesToFinalize;
  
  // New settings
  final String primaryColor;
  final bool requireSignature;
  final bool requirePhoto;
  final String defaultSortField;
  final bool enableSoundAlerts;
  final bool enableVibrationAlerts;

  const ScreenConfig({
    required this.documentType,
    required this.pageTitle,
    required this.searchHint,
    required this.enableBarcodeScanner,
    required this.enablePdfPrinting,
    required this.enableSerialNumberTracking,
    required this.visibleRoles,
    required this.detailPageTitle,
    required this.hidePricesForOperateurs,
    required this.allowedRolesToFinalize,
    required this.primaryColor,
    required this.requireSignature,
    required this.requirePhoto,
    required this.defaultSortField,
    required this.enableSoundAlerts,
    required this.enableVibrationAlerts,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      documentType: json['documentType'] as String,
      pageTitle: json['pageTitle'] as String,
      searchHint: json['searchHint'] as String,
      enableBarcodeScanner: json['enableBarcodeScanner'] as bool? ?? false,
      enablePdfPrinting: json['enablePdfPrinting'] as bool? ?? false,
      enableSerialNumberTracking: json['enableSerialNumberTracking'] as bool? ?? false,
      visibleRoles: List<String>.from(json['visibleRoles'] ?? const ['admin', 'commercial', 'operateur']),
      detailPageTitle: json['detailPageTitle'] as String? ?? '',
      hidePricesForOperateurs: json['hidePricesForOperateurs'] as bool? ?? false,
      allowedRolesToFinalize: List<String>.from(
        json['allowedRolesToFinalize'] ??
            const ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
      ),
      // New settings mappings with defaults
      primaryColor: json['primaryColor'] as String? ?? '#2196F3',
      requireSignature: json['requireSignature'] as bool? ?? false,
      requirePhoto: json['requirePhoto'] as bool? ?? false,
      defaultSortField: json['defaultSortField'] as String? ?? 'date',
      enableSoundAlerts: json['enableSoundAlerts'] as bool? ?? true,
      enableVibrationAlerts: json['enableVibrationAlerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'pageTitle': pageTitle,
        'searchHint': searchHint,
        'enableBarcodeScanner': enableBarcodeScanner,
        'enablePdfPrinting': enablePdfPrinting,
        'enableSerialNumberTracking': enableSerialNumberTracking,
        'visibleRoles': visibleRoles,
        'detailPageTitle': detailPageTitle,
        'hidePricesForOperateurs': hidePricesForOperateurs,
        'allowedRolesToFinalize': allowedRolesToFinalize,
        'primaryColor': primaryColor,
        'requireSignature': requireSignature,
        'requirePhoto': requirePhoto,
        'defaultSortField': defaultSortField,
        'enableSoundAlerts': enableSoundAlerts,
        'enableVibrationAlerts': enableVibrationAlerts,
      };

  ScreenConfig copyWith({
    String? pageTitle,
    String? searchHint,
    bool? enableBarcodeScanner,
    bool? enablePdfPrinting,
    bool? enableSerialNumberTracking,
    List<String>? visibleRoles,
    String? detailPageTitle,
    bool? hidePricesForOperateurs,
    List<String>? allowedRolesToFinalize,
    String? primaryColor,
    bool? requireSignature,
    bool? requirePhoto,
    String? defaultSortField,
    bool? enableSoundAlerts,
    bool? enableVibrationAlerts,
  }) {
    return ScreenConfig(
      documentType: documentType,
      pageTitle: pageTitle ?? this.pageTitle,
      searchHint: searchHint ?? this.searchHint,
      enableBarcodeScanner: enableBarcodeScanner ?? this.enableBarcodeScanner,
      enablePdfPrinting: enablePdfPrinting ?? this.enablePdfPrinting,
      enableSerialNumberTracking: enableSerialNumberTracking ?? this.enableSerialNumberTracking,
      visibleRoles: visibleRoles ?? this.visibleRoles,
      detailPageTitle: detailPageTitle ?? this.detailPageTitle,
      hidePricesForOperateurs: hidePricesForOperateurs ?? this.hidePricesForOperateurs,
      allowedRolesToFinalize: allowedRolesToFinalize ?? this.allowedRolesToFinalize,
      primaryColor: primaryColor ?? this.primaryColor,
      requireSignature: requireSignature ?? this.requireSignature,
      requirePhoto: requirePhoto ?? this.requirePhoto,
      defaultSortField: defaultSortField ?? this.defaultSortField,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      enableVibrationAlerts: enableVibrationAlerts ?? this.enableVibrationAlerts,
    );
  }
}
