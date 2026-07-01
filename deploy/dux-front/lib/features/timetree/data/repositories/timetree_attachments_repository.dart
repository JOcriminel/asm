import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_attachment_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_attachment.dart';

class TimetreeAttachmentsRepository {
  final TimetreeApi _api;
  TimetreeAttachmentsRepository(this._api);

  Future<List<TimetreeAttachment>> getAttachments(String eventId) async {
    try {
      final response = await _api.getAttachments(eventId);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeAttachmentDto.fromJson)
            .map(TimetreeAttachment.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'getAttachments failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  String _lookupMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'txt': return 'text/plain';
      case 'zip': return 'application/zip';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default: return 'application/octet-stream';
    }
  }

  Future<TimetreeAttachment> uploadAttachment(String eventId, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      final contentType = _lookupMimeType(fileName);

      // 1. Get presigned upload URL from backend
      final presignedResponse = await _api.getPresignedUploadUrl(eventId, fileName, fileSize, contentType);
      final uploadData = presignedResponse.data;
      if (uploadData == null || uploadData is! Map<String, dynamic>) {
        throw Exception('Invalide reponse pour le lien de chargement');
      }

      final String uploadUrl = uploadData['uploadUrl'];
      final String s3Key = uploadData['s3Key'];

      // 2. Put file to S3
      final fileStream = file.openRead();
      final uploadResponse = await _api.uploadFileToS3(uploadUrl, fileStream, fileSize, contentType);
      if (uploadResponse.statusCode != 200) {
        throw Exception('Le chargement vers S3 a echoue: ${uploadResponse.statusMessage}');
      }

      // 3. Confirm upload with backend
      final confirmResponse = await _api.confirmAttachmentUpload(eventId, fileName, s3Key, fileSize, contentType);
      final data = confirmResponse.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeAttachmentDto.fromJson(data);
        return TimetreeAttachment.fromDto(dto);
      }
      throw Exception('Format de reponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'uploadAttachment failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<List<int>> downloadAttachment(String attachmentId) async {
    try {
      // 1. Get presigned download URL
      final presignedResponse = await _api.getPresignedDownloadUrl(attachmentId);
      final downloadData = presignedResponse.data;
      if (downloadData == null || downloadData is! Map<String, dynamic>) {
        throw Exception('Invalide reponse pour le telechargement');
      }
      final String downloadUrl = downloadData['downloadUrl'];

      // 2. Download bytes directly from S3
      final response = await _api.downloadBytesFromUrl(downloadUrl);
      if (response.data is List<int>) {
        return response.data as List<int>;
      }
      throw Exception('Le telechargement a renvoye des donnees invalides');
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'downloadAttachment failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<String> getPresignedDownloadUrl(String attachmentId) async {
    try {
      final response = await _api.getPresignedDownloadUrl(attachmentId);
      final downloadData = response.data;
      if (downloadData == null || downloadData is! Map<String, dynamic>) {
        throw Exception('Invalide reponse pour le telechargement');
      }
      return downloadData['downloadUrl'] as String;
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'getPresignedDownloadUrl failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await _api.deleteAttachment(attachmentId);
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'deleteAttachment failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final timetreeAttachmentsRepositoryProvider = Provider<TimetreeAttachmentsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeAttachmentsRepository(TimetreeApi(dio));
});
