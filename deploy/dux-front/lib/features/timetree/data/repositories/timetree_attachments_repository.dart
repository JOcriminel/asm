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

  Future<TimetreeAttachment> uploadAttachment(String eventId, String filePath, String fileName) async {
    try {
      final response = await _api.uploadAttachment(eventId, filePath, fileName);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeAttachmentDto.fromJson(data);
        return TimetreeAttachment.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'uploadAttachment failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<List<int>> downloadAttachment(String attachmentId) async {
    try {
      final response = await _api.downloadAttachmentBytes(attachmentId);
      if (response.data is List<int>) {
        return response.data as List<int>;
      }
      throw Exception('Le téléchargement a renvoyé des données invalides');
    } catch (e) {
      AppLogger.e('TimetreeAttachmentsRepository', 'downloadAttachment failed', e);
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
