import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_chat_service.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';

class TimetreeChatState {
  final List<TimetreeMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const TimetreeChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  TimetreeChatState copyWith({
    List<TimetreeMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TimetreeChatState(
      messages: messages ?? this.messages,
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
      // Mark as read after loading initial messages
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
    try {
      final newMsg = await _chatService.sendMessage(_eventId, text, messageType: type, metadata: metadata);
      state = state.copyWith(
        messages: [newMsg, ...state.messages],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markRead() async {
    try {
      await _chatService.markRead(_eventId);
      _ref.read(timetreeChatUnreadCountsProvider.notifier).clearUnread(_eventId);
    } catch (_) {
      // Ignore background marker sync errors
    }
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

  TimetreeChatUnreadCountsNotifier(this._chatService) : super(const {}) {
    loadUnreadCounts();
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
  return TimetreeChatUnreadCountsNotifier(chatService);
});
