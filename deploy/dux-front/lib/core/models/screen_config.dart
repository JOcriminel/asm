class ScreenConfig {
  final String documentType;
  final String pageTitle;
  final String searchHint;
  final bool enableBarcodeScanner;
  final bool enablePdfPrinting;
  final bool enableSerialNumberTracking;
  final bool enableChecklistTracking;
  final List<String> visibleRoles;
  final String detailPageTitle;
  final bool hidePricesForOperateurs;
  final bool hidePrices;
  final List<String> allowedRolesToFinalize;
  final List<String> hidePricesForRoles;
  
  // New settings
  final String primaryColor;
  final bool requireSignature;
  final bool requirePhoto;
  final String defaultSortField;
  final bool enableSoundAlerts;
  final bool enableVibrationAlerts;
  final bool isActive;
  final String? category;

  // Fully dynamic UI configs
  final String? detailsFieldsConfig;
  final String? cardFieldsConfig;
  final String? searchFieldsConfig;
  final String? customFinalizeMessage;
  final String? statusFilters;

  const ScreenConfig({
    required this.documentType,
    required this.pageTitle,
    required this.searchHint,
    required this.enableBarcodeScanner,
    required this.enablePdfPrinting,
    required this.enableSerialNumberTracking,
    required this.enableChecklistTracking,
    required this.visibleRoles,
    required this.detailPageTitle,
    required this.hidePricesForOperateurs,
    required this.hidePrices,
    required this.allowedRolesToFinalize,
    this.hidePricesForRoles = const [],
    required this.primaryColor,
    required this.requireSignature,
    required this.requirePhoto,
    required this.defaultSortField,
    required this.enableSoundAlerts,
    required this.enableVibrationAlerts,
    required this.isActive,
    this.category,
    this.detailsFieldsConfig,
    this.cardFieldsConfig,
    this.searchFieldsConfig,
    this.customFinalizeMessage,
    this.statusFilters,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      documentType: json['documentType'] as String,
      pageTitle: json['pageTitle'] as String,
      searchHint: json['searchHint'] as String,
      enableBarcodeScanner: json['enableBarcodeScanner'] as bool? ?? false,
      enablePdfPrinting: json['enablePdfPrinting'] as bool? ?? false,
      enableSerialNumberTracking: json['enableSerialNumberTracking'] as bool? ?? false,
      enableChecklistTracking: json['enableChecklistTracking'] as bool? ?? false,
      visibleRoles: List<String>.from(json['visibleRoles'] ?? const ['admin', 'commercial', 'operateur']),
      detailPageTitle: json['detailPageTitle'] as String? ?? '',
      hidePricesForOperateurs: json['hidePricesForOperateurs'] as bool? ?? false,
      hidePrices: json['hidePrices'] as bool? ?? false,
      allowedRolesToFinalize: List<String>.from(
        json['allowedRolesToFinalize'] ??
            const ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'],
      ),
      hidePricesForRoles: List<String>.from(json['hidePricesForRoles'] ?? const []),
      primaryColor: json['primaryColor'] as String? ?? '#2196F3',
      requireSignature: json['requireSignature'] as bool? ?? false,
      requirePhoto: json['requirePhoto'] as bool? ?? false,
      defaultSortField: json['defaultSortField'] as String? ?? 'date',
      enableSoundAlerts: json['enableSoundAlerts'] as bool? ?? true,
      enableVibrationAlerts: json['enableVibrationAlerts'] as bool? ?? true,
      isActive: json['active'] as bool? ?? true,
      category: json['category'] as String?,
      detailsFieldsConfig: json['detailsFieldsConfig'] as String?,
      cardFieldsConfig: json['cardFieldsConfig'] as String?,
      searchFieldsConfig: json['searchFieldsConfig'] as String?,
      customFinalizeMessage: json['customFinalizeMessage'] as String?,
      statusFilters: json['statusFilters'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'pageTitle': pageTitle,
        'searchHint': searchHint,
        'enableBarcodeScanner': enableBarcodeScanner,
        'enablePdfPrinting': enablePdfPrinting,
        'enableSerialNumberTracking': enableSerialNumberTracking,
        'enableChecklistTracking': enableChecklistTracking,
        'visibleRoles': visibleRoles,
        'detailPageTitle': detailPageTitle,
        'hidePricesForOperateurs': hidePricesForOperateurs,
        'hidePrices': hidePrices,
        'allowedRolesToFinalize': allowedRolesToFinalize,
        'hidePricesForRoles': hidePricesForRoles,
        'primaryColor': primaryColor,
        'requireSignature': requireSignature,
        'requirePhoto': requirePhoto,
        'defaultSortField': defaultSortField,
        'enableSoundAlerts': enableSoundAlerts,
        'enableVibrationAlerts': enableVibrationAlerts,
        'active': isActive,
        'category': category,
        'detailsFieldsConfig': detailsFieldsConfig,
        'cardFieldsConfig': cardFieldsConfig,
        'searchFieldsConfig': searchFieldsConfig,
        'customFinalizeMessage': customFinalizeMessage,
        'statusFilters': statusFilters,
      };

  ScreenConfig copyWith({
    String? pageTitle,
    String? searchHint,
    bool? enableBarcodeScanner,
    bool? enablePdfPrinting,
    bool? enableSerialNumberTracking,
    bool? enableChecklistTracking,
    List<String>? visibleRoles,
    String? detailPageTitle,
    bool? hidePricesForOperateurs,
    bool? hidePrices,
    List<String>? allowedRolesToFinalize,
    List<String>? hidePricesForRoles,
    String? primaryColor,
    bool? requireSignature,
    bool? requirePhoto,
    String? defaultSortField,
    bool? enableSoundAlerts,
    bool? enableVibrationAlerts,
    bool? isActive,
    String? category,
    String? detailsFieldsConfig,
    String? cardFieldsConfig,
    String? searchFieldsConfig,
    String? customFinalizeMessage,
    String? statusFilters,
  }) {
    return ScreenConfig(
      documentType: documentType,
      pageTitle: pageTitle ?? this.pageTitle,
      searchHint: searchHint ?? this.searchHint,
      enableBarcodeScanner: enableBarcodeScanner ?? this.enableBarcodeScanner,
      enablePdfPrinting: enablePdfPrinting ?? this.enablePdfPrinting,
      enableSerialNumberTracking: enableSerialNumberTracking ?? this.enableSerialNumberTracking,
      enableChecklistTracking: enableChecklistTracking ?? this.enableChecklistTracking,
      visibleRoles: visibleRoles ?? this.visibleRoles,
      detailPageTitle: detailPageTitle ?? this.detailPageTitle,
      hidePricesForOperateurs: hidePricesForOperateurs ?? this.hidePricesForOperateurs,
      hidePrices: hidePrices ?? this.hidePrices,
      allowedRolesToFinalize: allowedRolesToFinalize ?? this.allowedRolesToFinalize,
      hidePricesForRoles: hidePricesForRoles ?? this.hidePricesForRoles,
      primaryColor: primaryColor ?? this.primaryColor,
      requireSignature: requireSignature ?? this.requireSignature,
      requirePhoto: requirePhoto ?? this.requirePhoto,
      defaultSortField: defaultSortField ?? this.defaultSortField,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      enableVibrationAlerts: enableVibrationAlerts ?? this.enableVibrationAlerts,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      detailsFieldsConfig: detailsFieldsConfig ?? this.detailsFieldsConfig,
      cardFieldsConfig: cardFieldsConfig ?? this.cardFieldsConfig,
      searchFieldsConfig: searchFieldsConfig ?? this.searchFieldsConfig,
      customFinalizeMessage: customFinalizeMessage ?? this.customFinalizeMessage,
      statusFilters: statusFilters ?? this.statusFilters,
    );
  }
}
