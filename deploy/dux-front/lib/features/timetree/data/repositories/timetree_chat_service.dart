import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_message_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';

class TimetreeChatPage {
  final List<TimetreeMessage> messages;
  final bool hasMore;
  final int page;
  final int size;

  const TimetreeChatPage({
    required this.messages,
    required this.hasMore,
    required this.page,
    required this.size,
  });
}

abstract class IChatService {
  Future<TimetreeChatPage> getMessages(String eventId, {required int page, required int size});
  Future<TimetreeMessage> sendMessage(String eventId, String text, {String messageType = 'TEXT', String? metadata});
  Future<void> markRead(String eventId);
  Future<Map<String, int>> getUnreadCounts();
}

class RestChatService implements IChatService {
  final TimetreeApi _api;
  RestChatService(this._api);

  @override
  Future<TimetreeChatPage> getMessages(String eventId, {required int page, required int size}) async {
    try {
      final response = await _api.getEventMessages(eventId, page: page, size: size);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final messagesList = data['messages'] as List? ?? [];
        final messages = messagesList
            .whereType<Map<String, dynamic>>()
            .map(TimetreeMessageDto.fromJson)
            .map(TimetreeMessage.fromDto)
            .toList();
        final hasMore = data['hasMore'] as bool? ?? false;
        final pageNum = (data['page'] as num?)?.toInt() ?? page;
        final sizeNum = (data['size'] as num?)?.toInt() ?? size;

        return TimetreeChatPage(
          messages: messages,
          hasMore: hasMore,
          page: pageNum,
          size: sizeNum,
        );
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('RestChatService', 'getMessages failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<TimetreeMessage> sendMessage(String eventId, String text, {String messageType = 'TEXT', String? metadata}) async {
    try {
      final response = await _api.sendEventMessage(eventId, text, messageType: messageType, metadata: metadata);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeMessageDto.fromJson(data);
        return TimetreeMessage.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('RestChatService', 'sendMessage failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> markRead(String eventId) async {
    try {
      await _api.markChatRead(eventId);
    } catch (e) {
      AppLogger.e('RestChatService', 'markRead failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, int>> getUnreadCounts() async {
    try {
      final response = await _api.getUnreadCounts();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
      return {};
    } catch (e) {
      AppLogger.e('RestChatService', 'getUnreadCounts failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [IChatService].
/// It returns [RestChatService] in Sprint 9 and can be overridden in tests
/// or swapped for STOMP/WebSocket implementation in Sprint 10 without affecting widgets.
final timetreeChatServiceProvider = Provider<IChatService>((ref) {
  final dio = ref.watch(dioProvider);
  return RestChatService(TimetreeApi(dio));
});
