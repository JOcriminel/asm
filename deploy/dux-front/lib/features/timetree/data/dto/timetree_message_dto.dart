import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';

class TimetreeMessageDto {
  final String id;
  final String eventId;
  final String message;
  final String messageType; // TEXT, IMAGE, FILE, SYSTEM
  final String? metadata;
  final DateTime sentAt;
  final TimetreeMemberDto sender;

  const TimetreeMessageDto({
    required this.id,
    required this.eventId,
    required this.message,
    required this.messageType,
    this.metadata,
    required this.sentAt,
    required this.sender,
  });

  factory TimetreeMessageDto.fromJson(Map<String, dynamic> json) {
    return TimetreeMessageDto(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? '').toString(),
      message: json['message'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      metadata: json['metadata'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      sender: TimetreeMemberDto.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'message': message,
      'messageType': messageType,
      'metadata': metadata,
      'sentAt': sentAt.toIso8601String(),
      'sender': sender.toJson(),
    };
  }
}
