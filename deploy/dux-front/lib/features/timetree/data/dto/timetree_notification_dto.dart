class TimetreeNotificationDto {
  final String id;
  final String recipientId;
  final String title;
  final String content;
  final String type;
  final String entityType; // EVENT, ATTACHMENT, MESSAGE
  final String entityId;
  final String actionType; // CREATED, UPDATED, DELETED, NEW, ASSIGNED
  final bool isRead;
  final DateTime createdAt;

  const TimetreeNotificationDto({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.content,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.actionType,
    required this.isRead,
    required this.createdAt,
  });

  factory TimetreeNotificationDto.fromJson(Map<String, dynamic> json) {
    return TimetreeNotificationDto(
      id: (json['id'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: (json['entityId'] ?? '').toString(),
      actionType: json['actionType'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'title': title,
      'content': content,
      'type': type,
      'entityType': entityType,
      'entityId': entityId,
      'actionType': actionType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
