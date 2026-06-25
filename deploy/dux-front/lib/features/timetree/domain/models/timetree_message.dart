import 'package:dux_front/features/timetree/data/dto/timetree_message_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';

enum TimetreeMessageType {
  text,
  image,
  file,
  system,
}

class TimetreeMessage {
  final String id;
  final String? clientMessageId;
  final String eventId;
  final String message;
  final TimetreeMessageType messageType;
  final String? metadata;
  final DateTime sentAt;
  final TimetreeMember sender;

  const TimetreeMessage({
    required this.id,
    this.clientMessageId,
    required this.eventId,
    required this.message,
    required this.messageType,
    this.metadata,
    required this.sentAt,
    required this.sender,
  });

  factory TimetreeMessage.fromDto(TimetreeMessageDto dto) {
    TimetreeMessageType type;
    switch (dto.messageType.toUpperCase()) {
      case 'IMAGE':
        type = TimetreeMessageType.image;
        break;
      case 'FILE':
        type = TimetreeMessageType.file;
        break;
      case 'SYSTEM':
        type = TimetreeMessageType.system;
        break;
      case 'TEXT':
      default:
        type = TimetreeMessageType.text;
        break;
    }

    return TimetreeMessage(
      id: dto.id,
      clientMessageId: dto.clientMessageId,
      eventId: dto.eventId,
      message: dto.message,
      messageType: type,
      metadata: dto.metadata,
      sentAt: dto.sentAt,
      sender: TimetreeMember.fromDto(dto.sender),
    );
  }

  TimetreeMessageDto toDto() {
    String typeStr;
    switch (messageType) {
      case TimetreeMessageType.image:
        typeStr = 'IMAGE';
        break;
      case TimetreeMessageType.file:
        typeStr = 'FILE';
        break;
      case TimetreeMessageType.system:
        typeStr = 'SYSTEM';
        break;
      case TimetreeMessageType.text:
      default:
        typeStr = 'TEXT';
        break;
    }

    return TimetreeMessageDto(
      id: id,
      clientMessageId: clientMessageId,
      eventId: eventId,
      message: message,
      messageType: typeStr,
      metadata: metadata,
      sentAt: sentAt,
      sender: sender.toDto(),
    );
  }
}
