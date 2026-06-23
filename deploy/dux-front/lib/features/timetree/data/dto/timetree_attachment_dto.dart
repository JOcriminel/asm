class TimetreeAttachmentDto {
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

  const TimetreeAttachmentDto({
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

  factory TimetreeAttachmentDto.fromJson(Map<String, dynamic> json) {
    return TimetreeAttachmentDto(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? '').toString(),
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      originalFilename: json['originalFilename'] as String? ?? json['fileName'] as String? ?? '',
      storedFilename: json['storedFilename'] as String? ?? json['filePath'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'originalFilename': originalFilename,
      'storedFilename': storedFilename,
      'fileSize': fileSize,
    };
  }
}
