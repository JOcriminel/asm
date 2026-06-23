import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';

class TimetreeChatTab extends ConsumerStatefulWidget {
  final String eventId;

  const TimetreeChatTab({super.key, required this.eventId});

  @override
  ConsumerState<TimetreeChatTab> createState() => _TimetreeChatTabState();
}

class _TimetreeChatTabState extends ConsumerState<TimetreeChatTab> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _sending = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _textController.removeListener(_onTextChanged);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(timetreeChatProvider(widget.eventId).notifier).sendTypingIndicator(true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isTyping) {
        _isTyping = false;
        ref.read(timetreeChatProvider(widget.eventId).notifier).sendTypingIndicator(false);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      ref.read(timetreeChatProvider(widget.eventId).notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(timetreeChatProvider(widget.eventId).notifier).sendMessage(text);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(timetreeChatProvider(widget.eventId));
    final authState = ref.watch(authControllerProvider);
    final currentUsername = authState.user?.username ?? '';

    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Erreur: ${chatState.error}'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(timetreeChatProvider(widget.eventId).notifier).loadInitial(),
                child: const Text('Recharger'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = chatState.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + (chatState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final message = messages[index];
                    final isSystem = message.messageType == TimetreeMessageType.system;
                    final isMe = message.sender.username == currentUsername;

                    if (isSystem) {
                      return _buildSystemBubble(message);
                    }

                    return _buildUserBubble(message, isMe);
                  },
                ),
        ),
        if (chatState.activeTypers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 8),
                Text(
                  '${chatState.activeTypers.join(', ')} est en train d\'écrire...',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Discussion vide',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Soyez le premier à envoyer un message !',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(TimetreeMessage msg) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${msg.sender.fullName} ${msg.message}',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserBubble(TimetreeMessage msg, bool isMe) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm', 'fr_FR').format(msg.sentAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  msg.sender.fullName,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 2),
                    child: Text(
                      timeStr,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 2),
                    child: Text(
                      timeStr,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Écrire un message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            color: theme.colorScheme.primary,
            onPressed: _sending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
