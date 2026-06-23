import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_chat_service.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_websocket_service.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_message_dto.dart';
import 'package:dux_front/core/utils/logger.dart';

class TimetreeChatState {
  final List<TimetreeMessage> messages;
  final List<String> activeTypers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const TimetreeChatState({
    this.messages = const [],
    this.activeTypers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  TimetreeChatState copyWith({
    List<TimetreeMessage>? messages,
    List<String>? activeTypers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TimetreeChatState(
      messages: messages ?? this.messages,
      activeTypers: activeTypers ?? this.activeTypers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class TimetreeChatNotifier extends StateNotifier<TimetreeChatState> {
  final IChatService _chatService;
  final String _eventId;
  final Ref _ref;

  TimetreeChatNotifier(this._chatService, this._eventId, this._ref)
      : super(const TimetreeChatState()) {
    loadInitial();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    final wsService = _ref.read(timetreeWebSocketServiceProvider);
    
    // Connect first if not already connected
    wsService.connect();

    // Subscribe to chat message broadcasts
    wsService.subscribe('/topic/event.$_eventId.chat', (payload) {
      try {
        final newMsg = TimetreeMessage.fromDto(
          TimetreeMessageDto.fromJson(payload),
        );
        
        // Prevent duplicate messages
        final exists = state.messages.any((m) => m.id == newMsg.id);
        if (!exists) {
          state = state.copyWith(
            messages: [newMsg, ...state.messages],
          );
        }

        // Auto-clear typing status for the sender when they send a message
        if (newMsg.sender?.username != null) {
          final typers = List<String>.from(state.activeTypers);
          typers.remove(newMsg.sender!.username);
          state = state.copyWith(activeTypers: typers);
        }
      } catch (e) {
        AppLogger.e('ChatProvider', 'Error parsing real-time message: $e');
      }
    });

    // Subscribe to typing indicators
    wsService.subscribe('/topic/event.$_eventId.typing', (payload) {
      final username = payload['username'] as String?;
      final isTyping = payload['isTyping'] as bool? ?? false;
      final currentUser = _ref.read(authControllerProvider).user?.username;

      if (username != null && username != currentUser) {
        final typers = List<String>.from(state.activeTypers);
        if (isTyping) {
          if (!typers.contains(username)) {
            typers.add(username);
          }
        } else {
          typers.remove(username);
        }
        state = state.copyWith(activeTypers: typers);
      }
    });
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pageData = await _chatService.getMessages(_eventId, page: 0, size: 20);
      state = state.copyWith(
        messages: pageData.messages,
        hasMore: pageData.hasMore,
        currentPage: 0,
        isLoading: false,
      );
      markRead();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final pageData = await _chatService.getMessages(_eventId, page: nextPage, size: 20);
      state = state.copyWith(
        messages: [...state.messages, ...pageData.messages],
        hasMore: pageData.hasMore,
        currentPage: nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text, {String type = 'TEXT', String? metadata}) async {
    final clientMsgId = 'msg-${DateTime.now().millisecondsSinceEpoch}-${_ref.read(authControllerProvider).user?.username}';
    final wsService = _ref.read(timetreeWebSocketServiceProvider);

    final payload = {
      'clientMessageId': clientMsgId,
      'message': text,
      'messageType': type,
      'metadata': metadata,
    };

    if (wsService.isConnected) {
      wsService.send('/app/event.$_eventId.send', payload);
    } else {
      // Offline fallback: save to local queue via websocket service send method
      wsService.send('/app/event.$_eventId.send', payload);
      
      // Also provisionally add to local state to maintain responsiveness
      final currentUser = _ref.read(authControllerProvider).user;
      if (currentUser != null) {
        final tempMsg = TimetreeMessage(
          id: clientMsgId,
          eventId: _eventId,
          message: text,
          messageType: type == 'IMAGE'
              ? TimetreeMessageType.image
              : type == 'FILE'
                  ? TimetreeMessageType.file
                  : TimetreeMessageType.text,
          metadata: metadata,
          sentAt: DateTime.now(),
          sender: TimetreeMember(
            id: currentUser.id,
            username: currentUser.username,
            fullName: currentUser.fullName,
            email: '',
            role: currentUser.role,
          ),
        );
        state = state.copyWith(
          messages: [tempMsg, ...state.messages],
        );
      }
    }
  }

  void sendTypingIndicator(bool isTyping) {
    final wsService = _ref.read(timetreeWebSocketServiceProvider);
    if (wsService.isConnected) {
      wsService.send('/app/event.$_eventId.typing', {'isTyping': isTyping});
    }
  }

  Future<void> markRead() async {
    try {
      final wsService = _ref.read(timetreeWebSocketServiceProvider);
      if (wsService.isConnected) {
        wsService.send('/app/event.$_eventId.read', {});
      } else {
        await _chatService.markRead(_eventId);
      }
      _ref.read(timetreeChatUnreadCountsProvider.notifier).clearUnread(_eventId);
    } catch (_) {
      // Ignore background marker sync errors
    }
  }

  @override
  void dispose() {
    final wsService = _ref.read(timetreeWebSocketServiceProvider);
    wsService.unsubscribe('/topic/event.$_eventId.chat');
    wsService.unsubscribe('/topic/event.$_eventId.typing');
    super.dispose();
  }
}

/// Family Provider for Chat room states
final timetreeChatProvider =
    StateNotifierProvider.family.autoDispose<TimetreeChatNotifier, TimetreeChatState, String>((ref, eventId) {
  final chatService = ref.watch(timetreeChatServiceProvider);
  return TimetreeChatNotifier(chatService, eventId, ref);
});

/// StateNotifier for tracking unread message counts across events
class TimetreeChatUnreadCountsNotifier extends StateNotifier<Map<String, int>> {
  final IChatService _chatService;
  final Ref _ref;

  TimetreeChatUnreadCountsNotifier(this._chatService, this._ref) : super(const {}) {
    loadUnreadCounts();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    final wsService = _ref.read(timetreeWebSocketServiceProvider);
    wsService.connect();

    // Listen for real-time unread badge synchronization across tabs
    final currentUserId = _ref.read(authControllerProvider).user?.id;
    if (currentUserId != null) {
      wsService.subscribe('/topic/user.$currentUserId.unread', (payload) {
        try {
          if (payload is Map<String, dynamic>) {
            state = payload.map((key, value) => MapEntry(key, (value as num).toInt()));
          }
        } catch (e) {
          AppLogger.e('UnreadCounts', 'Error parsing unread count payload: $e');
        }
      });
    }
  }

  Future<void> loadUnreadCounts() async {
    try {
      final counts = await _chatService.getUnreadCounts();
      state = counts;
    } catch (_) {
      // Ignore background errors
    }
  }

  void clearUnread(String eventId) {
    if (state.containsKey(eventId)) {
      final newState = Map<String, int>.from(state);
      newState.remove(eventId);
      state = newState;
    }
  }

  void incrementUnread(String eventId) {
    final newState = Map<String, int>.from(state);
    newState[eventId] = (newState[eventId] ?? 0) + 1;
    state = newState;
  }
}

final timetreeChatUnreadCountsProvider =
    StateNotifierProvider.autoDispose<TimetreeChatUnreadCountsNotifier, Map<String, int>>((ref) {
  final chatService = ref.watch(timetreeChatServiceProvider);
  return TimetreeChatUnreadCountsNotifier(chatService, ref);
});
