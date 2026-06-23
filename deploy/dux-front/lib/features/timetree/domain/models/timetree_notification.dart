import 'package:dux_front/features/timetree/data/dto/timetree_notification_dto.dart';

class TimetreeNotification {
  final String id;
  final String recipientId;
  final String title;
  final String content;
  final String type;
  final String entityType;
  final String entityId;
  final String actionType;
  final bool isRead;
  final DateTime createdAt;

  const TimetreeNotification({
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

  factory TimetreeNotification.fromDto(TimetreeNotificationDto dto) {
    return TimetreeNotification(
      id: dto.id,
      recipientId: dto.recipientId,
      title: dto.title,
      content: dto.content,
      type: dto.type,
      entityType: dto.entityType,
      entityId: dto.entityId,
      actionType: dto.actionType,
      isRead: dto.isRead,
      createdAt: dto.createdAt,
    );
  }

  TimetreeNotificationDto toDto() {
    return TimetreeNotificationDto(
      id: id,
      recipientId: recipientId,
      title: title,
      content: content,
      type: type,
      entityType: entityType,
      entityId: entityId,
      actionType: actionType,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}
