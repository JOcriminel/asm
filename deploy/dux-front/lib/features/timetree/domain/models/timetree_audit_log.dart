class TimetreeAuditLog {
  final String id;
  final String? username;
  final String action;
  final String entityType;
  final String? entityId;
  final String result;
  final String? ipAddress;
  final DateTime actionDate;
  final String? details;

  const TimetreeAuditLog({
    required this.id,
    this.username,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.result,
    this.ipAddress,
    required this.actionDate,
    this.details,
  });

  factory TimetreeAuditLog.fromJson(Map<String, dynamic> json) {
    return TimetreeAuditLog(
      id: (json['id'] ?? '').toString(),
      username: json['username'] as String?,
      action: json['action'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId']?.toString(),
      result: json['result'] as String? ?? '',
      ipAddress: json['ipAddress'] as String?,
      actionDate: DateTime.parse(json['actionDate'] as String).toLocal(),
      details: json['details'] as String?,
    );
  }
}
