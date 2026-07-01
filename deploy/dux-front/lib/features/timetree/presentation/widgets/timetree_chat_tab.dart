import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_attachments_repository.dart';

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
                    final isAttachment = message.metadata != null && message.metadata!.startsWith('ATTACHMENT_UPLOADED:');

                    if (isAttachment) {
                      return _buildAttachmentBubble(message, isMe);
                    }

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

  Widget _buildAttachmentBubble(TimetreeMessage msg, bool isMe) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm', 'fr_FR').format(msg.sentAt);
    final parts = msg.metadata!.split(':');
    final attachmentId = parts.length > 1 ? parts[1] : '';
    final fileName = msg.message.replaceAll('A ajouté la pièce jointe: ', '');

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
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TimetreeAttachmentPreview(
                        attachmentId: attachmentId,
                        fileName: fileName,
                        eventId: widget.eventId,
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

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                title: const Text('Galerie (Image)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadMedia(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadMedia(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.amber),
                title: const Text('Fichier'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final filePath = pickedFile.path;
        final fileName = pickedFile.name;
        await _uploadAndNotify(filePath, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur d\'importation d\'image: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'xlsx', 'zip', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        await _uploadAndNotify(filePath, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur d\'importation de fichier: $e');
    }
  }

  Future<void> _uploadAndNotify(String filePath, String fileName) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Envoi du fichier en cours...')),
    );

    try {
      final repository = ref.read(timetreeAttachmentsRepositoryProvider);
      await repository.uploadAttachment(widget.eventId, filePath, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier envoyé avec succès !')),
        );
        ref.read(timetreeChatProvider(widget.eventId).notifier).loadInitial();
      }
    } catch (e) {
      _showErrorSnackBar('Le chargement a échoué: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: theme.colorScheme.primary,
            onPressed: _sending ? null : _showAttachmentOptions,
          ),
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

class TimetreeAttachmentPreview extends ConsumerStatefulWidget {
  final String attachmentId;
  final String fileName;
  final String eventId;

  const TimetreeAttachmentPreview({
    super.key,
    required this.attachmentId,
    required this.fileName,
    required this.eventId,
  });

  @override
  ConsumerState<TimetreeAttachmentPreview> createState() => _TimetreeAttachmentPreviewState();
}

class _TimetreeAttachmentPreviewState extends ConsumerState<TimetreeAttachmentPreview> {
  String? _downloadUrl;
  bool _loading = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadUrl();
  }

  Future<void> _loadDownloadUrl() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(timetreeAttachmentsRepositoryProvider);
      final url = await repo.getPresignedDownloadUrl(widget.attachmentId);
      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isImage() {
    final ext = widget.fileName.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif'].contains(ext);
  }

  Future<void> _downloadFile() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final repo = ref.read(timetreeAttachmentsRepositoryProvider);
      final bytes = await repo.downloadAttachment(widget.attachmentId);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Téléchargé: ${widget.fileName}\nSauvegardé dans Documents'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_loading) {
      return Container(
        height: 100,
        width: 150,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isImage() && _downloadUrl != null) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(widget.fileName, style: const TextStyle(color: Colors.white)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: _downloadFile,
                    ),
                  ],
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: Image.network(_downloadUrl!),
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxHeight: 180),
          child: Image.network(
            _downloadUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 100,
                width: 150,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                  SizedBox(height: 4),
                  Text('Échec chargement image', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.surfaceContainer
          : Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.fileName.endsWith('.pdf')
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.fileName.split('.').last.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: _downloading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded, size: 20),
            onPressed: _downloadFile,
          ),
        ],
      ),
    );
  }
}
