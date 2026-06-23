import 'package:dux_front/features/timetree/data/dto/timetree_attachment_dto.dart';

class TimetreeAttachment {
  final String id;
  final String eventId;
  final String fileName;
  final String filePath;
  final String fileType;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String originalFilename;
  final String storedFilename;
  final int fileSize;

  const TimetreeAttachment({
    required this.id,
    required this.eventId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.originalFilename,
    required this.storedFilename,
    required this.fileSize,
  });

  factory TimetreeAttachment.fromDto(TimetreeAttachmentDto dto) {
    return TimetreeAttachment(
      id: dto.id,
      eventId: dto.eventId,
      fileName: dto.fileName,
      filePath: dto.filePath,
      fileType: dto.fileType,
      uploadedBy: dto.uploadedBy,
      uploadedAt: dto.uploadedAt,
      originalFilename: dto.originalFilename,
      storedFilename: dto.storedFilename,
      fileSize: dto.fileSize,
    );
  }

  TimetreeAttachmentDto toDto() {
    return TimetreeAttachmentDto(
      id: id,
      eventId: eventId,
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      originalFilename: originalFilename,
      storedFilename: storedFilename,
      fileSize: fileSize,
    );
  }

  String get sizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
