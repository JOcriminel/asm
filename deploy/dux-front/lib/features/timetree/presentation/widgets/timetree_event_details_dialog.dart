import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';

class TimetreeEventDetailsDialog extends ConsumerStatefulWidget {
  final TimetreeEvent event;
  final VoidCallback onRefresh;
  final VoidCallback onEditClicked;

  const TimetreeEventDetailsDialog({
    super.key,
    required this.event,
    required this.onRefresh,
    required this.onEditClicked,
  });

  @override
  ConsumerState<TimetreeEventDetailsDialog> createState() => _TimetreeEventDetailsDialogState();
}

class _TimetreeEventDetailsDialogState extends ConsumerState<TimetreeEventDetailsDialog> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _sending = false;

  bool _isLiked = false;
  bool _isAttending = false;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  String formatDetailsDate(DateTime dt) {
    String dayAbbr = DateFormat('E', 'fr_FR').format(dt).toLowerCase();
    if (dayAbbr.endsWith('.')) {
      dayAbbr = dayAbbr.substring(0, dayAbbr.length - 1);
    }
    final day = dt.day;
    final monthStr = DateFormat('MMMM', 'fr_FR').format(dt).toLowerCase();
    final year = dt.year;
    return "$dayAbbr. $day $monthStr $year";
  }

  String formatFrenchTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  String getReminderLabel(DateTime start, List<DateTime> reminders) {
    if (reminders.isEmpty) return "Pas de rappel";
    final diff = start.difference(reminders.first);
    if (diff.inMinutes == 10) return "10 min avant";
    if (diff.inMinutes == 15) return "15 min avant";
    if (diff.inHours == 1) return "1 heure avant";
    if (diff.inDays == 1) return "1 jour avant";
    return "${diff.inMinutes} min avant";
  }

  String getColorName(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return 'Apple red';
    final colorVal = int.tryParse(colorStr);
    if (colorVal == null) return 'Apple red';
    final color = Color(colorVal);
    if (color.value == Colors.blue.value) return 'Bleu';
    if (color.value == Colors.green.value) return 'Vert';
    if (color.value == Colors.red.value) return 'Rouge';
    if (color.value == Colors.orange.value) return 'Orange';
    if (color.value == Colors.purple.value) return 'Violet';
    if (color.value == Colors.teal.value) return 'Turquoise';
    if (color.value == const Color(0xFF10B981).value) return 'Emerald green';
    return 'Apple red';
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(timetreeChatProvider(widget.event.id).notifier).sendMessage(text);
      _textController.clear();
      setState(() {}); // Rebuild to clear send button
      _scrollToBottom();
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation
              Navigator.pop(context); // Close details dialog
              try {
                await ref.read(timetreeEventsProvider.notifier).deleteEvent(widget.event.id);
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Événement supprimé')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final iconColor = const Color(0xFF10B981); // Emerald green/teal icon color

    final ev = widget.event;
    final chatState = ref.watch(timetreeChatProvider(ev.id));
    final authState = ref.watch(authControllerProvider);
    final currentUsername = authState.user?.username ?? '';

    final dateStr = formatDetailsDate(ev.startDate);
    final timeStr = ev.allDay ? 'Jour entier' : formatFrenchTime(ev.startDate);

    // Messages ordered chronologically (oldest at the top, newest at the bottom)
    final messages = chatState.messages.reversed.toList();

    // Listen to changes in chat messages to auto-scroll down
    ref.listen<TimetreeChatState>(timetreeChatProvider(ev.id), (previous, next) {
      if (next.messages.length != (previous?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    });

    return Dialog.fullscreen(
      backgroundColor: bgColor,
      child: Scaffold(
        backgroundColor: bgColor,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Pinned Header
            _buildHeader(context, iconColor, textColor),

            // Scrollable area combining details and discussion comments
            Expanded(
              child: chatState.isLoading && chatState.messages.isEmpty
                  ? Center(child: CircularProgressIndicator(color: iconColor))
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large Event Details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.9),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Event Rows (Alarm, Calendar/Category, Tag/Color name)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  icon: Icons.alarm_on_rounded,
                                  iconColor: iconColor,
                                  text: getReminderLabel(ev.startDate, ev.reminders),
                                  textColor: textColor,
                                ),
                                _buildDetailRow(
                                  icon: Icons.calendar_today_rounded,
                                  iconColor: iconColor,
                                  text: ev.calendarName ?? 'Travail',
                                  textColor: textColor,
                                ),
                                _buildDetailRow(
                                  icon: Icons.local_offer_outlined,
                                  iconColor: iconColor,
                                  text: getColorName(ev.color),
                                  textColor: textColor,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Center divider "Aujourd'hui"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 0.8)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    "Aujourd'hui",
                                    style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 0.8)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Log row: creator avatar and "Événement créé"
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  child: Icon(Icons.person, size: 12, color: subTextColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Événement créé',
                                  style: TextStyle(color: subTextColor, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Chat bubbles list
                          if (messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Aucun commentaire pour le moment.',
                                  style: TextStyle(color: subTextColor, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: messages.length,
                              itemBuilder: (context, idx) {
                                final msg = messages[idx];
                                final isSystem = msg.messageType == TimetreeMessageType.system;
                                final isMe = msg.sender.username == currentUsername;

                                if (isSystem) {
                                  return _buildSystemBubble(msg, subTextColor);
                                }
                                return _buildUserBubble(msg, isMe, textColor, isDark);
                              },
                            ),
                        ],
                      ),
                    ),
            ),

            // Pinned Bottom Input Bar
            _buildBottomInputBar(isDark, bgColor, textColor, iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color iconColor, Color textColor) {
    final ev = widget.event;
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toUpperCase() ?? 'MEMBER';
    final isEditable = !ev.locked || (userRole == 'ADMIN' || userRole == 'ADMINISTRATEUR' || userRole == 'CHEF');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 22),
              onPressed: () => Navigator.pop(context),
            ),

            // Overlapping/horizontal row of participants
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 32,
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: ev.participants.length,
                    itemBuilder: (context, idx) {
                      final p = ev.participants[idx];
                      final initials = p.fullName.isNotEmpty ? p.fullName.substring(0, 1).toUpperCase() : '?';
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.purple.shade300,
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Top-right dropdown menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: iconColor, size: 28),
              color: const Color(0xFF262626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 40),
              onSelected: (value) async {
                if (value == 'modifier') {
                  if (isEditable) {
                    Navigator.pop(context);
                    widget.onEditClicked();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cet événement est verrouillé (Admin/Chef uniquement).'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else if (value == 'copier') {
                  // Implement copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copié !')),
                  );
                } else if (value == 'supprimer') {
                  _confirmDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'modifier',
                  child: Text('Modifier', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const PopupMenuItem(
                  value: 'copier',
                  child: Text('Copier', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const PopupMenuItem(
                  value: 'copier_plusieurs',
                  child: Text('Copier sur plusieurs dates', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const PopupMenuItem(
                  value: 'partager',
                  child: Text('Partager', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const PopupMenuItem(
                  value: 'supprimer',
                  child: Text('Supprimer', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(TimetreeMessage msg, Color subTextColor) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        '${msg.sender.fullName} ${msg.message}',
        style: TextStyle(fontSize: 11, color: subTextColor, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserBubble(TimetreeMessage msg, bool isMe, Color textColor, bool isDark) {
    final timeStr = DateFormat('HH:mm').format(msg.sentAt);
    final initials = msg.sender.fullName.isNotEmpty ? msg.sender.fullName.substring(0, 1).toUpperCase() : '?';

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // Emerald green bubble
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.zero,
                  ),
                ),
                child: Text(
                  msg.message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF10B981),
              child: Text(
                initials,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.purple.shade300,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.sender.fullName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262626) : Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.zero,
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg.message,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBottomInputBar(bool isDark, Color bgColor, Color textColor, Color iconColor) {
    final showSendButton = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? Colors.redAccent : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isLiked = !_isLiked;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isLiked ? 'Événement aimé !' : 'Mention J\'aime retirée'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.how_to_reg_rounded,
                color: _isAttending ? iconColor : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isAttending = !_isAttending;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isAttending ? 'Participation confirmée !' : 'Participation annulée'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Colors.grey),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partager une image bientôt disponible dans cette discussion.')),
                );
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Commentaire',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : showSendButton
                            ? GestureDetector(
                                onTap: _sendMessage,
                                child: Icon(Icons.send_rounded, color: iconColor, size: 20),
                              )
                            : const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
