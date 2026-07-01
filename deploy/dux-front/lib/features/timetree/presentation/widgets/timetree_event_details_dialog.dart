import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_attachments_repository.dart';
import 'timetree_chat_tab.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/command_details/presentation/screens/command_details_screen.dart';
import 'package:dux_front/features/bon_preparation/presentation/screens/bon_preparation_detail_screen.dart';
import 'package:dux_front/features/bon_sortie/presentation/screens/bon_sortie_detail_screen.dart';
import 'package:dux_front/features/clients/presentation/screens/client_details_screen.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field_value.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_tag.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

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
  Set<String> _tierCodes = {};
  List<Map<String, dynamic>> _rawTypes = [];

  Future<void> _loadTierTypes() async {
    try {
      final types = await ref.read(screenConfigControllerProvider.notifier).fetchAllTierTypes();
      if (mounted) {
        setState(() {
          _rawTypes = types;
          _tierCodes = types
              .map((t) => (t['typeCode'] ?? t['code'])?.toString().trim().toUpperCase())
              .whereType<String>()
              .toSet();
        });
      }
    } catch (_) {}
  }

  /// Navigate to the appropriate detail screen for any document type or tier type.
  /// BC / BCC / DevC / any other → CommandDetailsScreen (generic)
  /// BS                           → BonSortieDetailScreen
  /// BP / DPR / PR                → BonPreparationDetailScreen
  /// Tier types (Client, etc.)    → ClientDetailsScreen
  void _navigateToDocument(BuildContext ctx, String id, String type) {
    if (id.isEmpty) return;
    final t = type.trim().toUpperCase();
    if (_tierCodes.contains(t)) {
      String? resolvedTypeTier;
      for (final rawType in _rawTypes) {
        final typeCodeVal = (rawType['typeCode'] ?? rawType['code'])?.toString().trim().toUpperCase();
        if (typeCodeVal == t) {
          resolvedTypeTier = rawType['code']?.toString();
          break;
        }
      }
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => ClientDetailsScreen(clientId: id, typeTier: resolvedTypeTier),
        ),
      );
    } else if (t.startsWith('BS') || t == 'BON_SORTIE') {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => BonSortieDetailScreen(sortieId: id, isFromCalendar: true),
        ),
      );
    } else if (t.startsWith('BP') || t.startsWith('PR') || t == 'DPR' || t == 'BON_PREPARATION') {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => BonPreparationDetailScreen(preparationId: id, docType: type, isFromCalendar: true),
        ),
      );
    } else {
      // CommandDetailsScreen is the generic fallback — handles BC, BCC, DevC,
      // factures, avoirs, proformas and any other doc type that the ERP returns.
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => CommandDetailsScreen(commandId: id, isFromCalendar: true),
        ),
      );
    }
  }
  bool _sending = false;

  bool _isLiked = false;
  bool _isAttending = false;

  List<TimetreeCustomFieldValue> _customFieldValues = [];
  bool _loadingCustomFields = false;

  @override
  void initState() {
    super.initState();
    _loadCustomFieldValues();
    _loadTierTypes();
    // Scroll to bottom when frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadCustomFieldValues() async {
    setState(() => _loadingCustomFields = true);
    try {
      final baseEventId = widget.event.id.split('_rec_').first;
      final values = await ref.read(timetreeCustomFieldsRepositoryProvider).getCustomFieldValues('EVENT', baseEventId);
      if (mounted) {
        setState(() {
          _customFieldValues = values;
          _loadingCustomFields = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCustomFields = false);
      }
    }
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
    final labels = reminders.map((rem) {
      final diff = start.difference(rem);
      final diffMins = diff.inMinutes;
      if ((diffMins - 10).abs() <= 2) return "10 min avant";
      if ((diffMins - 15).abs() <= 2) return "15 min avant";
      if ((diffMins - 60).abs() <= 5) return "1 heure avant";
      if ((diffMins - 1440).abs() <= 10) return "1 jour avant";
      return "$diffMins min avant";
    }).toList();
    return labels.join(', ');
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
                          const SizedBox(height: 16),
 
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Card 1: Time, Alarm & Agenda
                                _buildDetailsCard(
                                  isDark: isDark,
                                  children: [
                                    _buildDetailRow(
                                      icon: Icons.access_time_rounded,
                                      iconColor: iconColor,
                                      text: formatDateTimeRange(ev),
                                      textColor: textColor,
                                    ),
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
                                    if (ev.description != null && ev.description!.isNotEmpty)
                                      _buildDetailRow(
                                        icon: Icons.description_outlined,
                                        iconColor: iconColor,
                                        text: ev.description!,
                                        textColor: textColor,
                                      ),
                                    if (ev.attachedDocumentId != null && ev.attachedDocumentId!.isNotEmpty)
                                      ...((String docIdStr, String docTypeStr, String docCodeStr, String clientNameStr) {
                                        final docIds = docIdStr.split(',');
                                        final docTypes = docTypeStr.split(',');
                                        final docCodes = docCodeStr.split(',');
                                        final clientNames = clientNameStr.split(',');
                                        final list = <Widget>[];
                                        for (int i = 0; i < docIds.length; i++) {
                                          final id = docIds[i].trim();
                                          if (id.isEmpty) continue;
                                          final type = i < docTypes.length ? docTypes[i].trim() : 'BC';
                                          final code = i < docCodes.length ? docCodes[i].trim() : '';
                                          final client = i < clientNames.length ? clientNames[i].trim() : '';
                                          list.add(
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: InkWell(
                                                onTap: () => _navigateToDocument(context, id, type),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: iconColor.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: iconColor.withValues(alpha: 0.15),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: iconColor.withValues(alpha: 0.12),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.insert_drive_file_rounded,
                                                          color: iconColor,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              '$type $code',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15,
                                                                color: textColor,
                                                              ),
                                                            ),
                                                            if (client.isNotEmpty) ...[
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                client,
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: textColor.withValues(alpha: 0.6),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      TextButton.icon(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: iconColor,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        ),
                                                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                                        label: const Text(
                                                          'Détails',
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                        ),
                                                        onPressed: () => _navigateToDocument(context, id, type),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return list;
                                      })(ev.attachedDocumentId!, ev.attachedDocumentType ?? '', ev.attachedDocumentCode ?? '', ev.attachedClientName ?? ''),
                                  ],
                                ),
                                _buildDetailsCard(
                                  isDark: isDark,
                                  children: [
                                    _buildDetailRow(
                                      icon: Icons.info_outline_rounded,
                                      iconColor: iconColor,
                                      text: "Nom: ${ev.nomEvent ?? ev.title}",
                                      textColor: textColor,
                                    ),
                                    _buildDetailRow(
                                      icon: Icons.repeat_rounded,
                                      iconColor: iconColor,
                                      text: "Répétition: ${getRecurrenceLabel(ev.recurrenceRule, ev.recurrenceEndDate)}",
                                      textColor: textColor,
                                    ),
                                    _buildDetailRow(
                                      icon: Icons.hourglass_empty_rounded,
                                      iconColor: iconColor,
                                      text: "Statut: ${getStatusLabel(ev.status)}",
                                      textColor: textColor,
                                    ),
                                    _buildDetailRow(
                                      icon: Icons.priority_high_rounded,
                                      iconColor: iconColor,
                                      text: "Priorité: ${getPriorityLabel(ev.priority)}",
                                      textColor: textColor,
                                    ),
                                    if (ev.isPrivate)
                                      _buildDetailRow(
                                        icon: Icons.lock_outline_rounded,
                                        iconColor: iconColor,
                                        text: "Événement Privé",
                                        textColor: textColor,
                                      ),
                                    if (ev.locked)
                                      _buildDetailRow(
                                        icon: Icons.lock_rounded,
                                        iconColor: Colors.redAccent,
                                        text: "Événement Verrouillé",
                                        textColor: textColor,
                                      ),
                                    _buildTagsRow(ev.tags, iconColor, textColor),
                                    _buildDependenciesRow(ev.dependencies, iconColor, textColor),
                                  ],
                                ),

                                // Card 3: Participants
                                if (ev.participants.isNotEmpty)
                                  _buildDetailsCard(
                                    isDark: isDark,
                                    children: [
                                      _buildParticipantsListRow(ev.participants, iconColor, textColor),
                                    ],
                                  ),

                                // Card 4: Champs Personnalisés
                                if (!_loadingCustomFields && _customFieldValues.any((cfv) => (cfv.value ?? '').isNotEmpty))
                                  _buildDetailsCard(
                                    isDark: isDark,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                                        child: Text(
                                          "CHAMPS PERSONNALISÉS",
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      ..._customFieldValues.map((cfv) {
                                        final resolved = _resolveValueAndEmoji(cfv);
                                        final content = resolved['content'] ?? '';
                                        if (content.isEmpty) return const SizedBox.shrink();
                                        
                                        final labelLower = cfv.field.label.toLowerCase();
                                        final isLocation = labelLower.contains('lieu') ||
                                            labelLower.contains('adresse') ||
                                            labelLower.contains('location') ||
                                            labelLower.contains('coordon');
                                            
                                        if (isLocation) {
                                          return _buildLocationRow(
                                            label: cfv.field.label,
                                            address: content,
                                            iconColor: iconColor,
                                            textColor: textColor,
                                            subTextColor: subTextColor,
                                          );
                                        }

                                        final emoji = resolved['emoji'] ?? '';
                                        return _buildCustomFieldRow(
                                          label: cfv.field.label,
                                          emoji: emoji,
                                          content: content,
                                          iconColor: iconColor,
                                          textColor: textColor,
                                          subTextColor: subTextColor,
                                        );
                                      }),
                                    ],
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
                                final isAttachment = msg.metadata != null && msg.metadata!.startsWith('ATTACHMENT_UPLOADED:');

                                if (isAttachment) {
                                  return _buildAttachmentBubble(msg, isMe, textColor, isDark);
                                }
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

            // Event Title in the navigation bar (middle)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ev.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
                } else if (value == 'traceability') {
                  _showTraceabilityDialog(context);
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
                if (userRole == 'ADMIN' || userRole == 'ADMINISTRATEUR' || userRole == 'CHEF')
                  const PopupMenuItem(
                    value: 'traceability',
                    child: Text('Traçabilité / Historique', style: TextStyle(color: Colors.white, fontSize: 14)),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _resolveValueAndEmoji(TimetreeCustomFieldValue val) {
    final rawValue = val.value ?? '';
    if (rawValue.isEmpty) {
      return {'emoji': '', 'content': ''};
    }

    String content = rawValue;
    String emoji = val.field.emoji ?? '';

    final fieldType = val.field.fieldType.toUpperCase();
    if (fieldType == 'BOOLEAN') {
      content = rawValue.toLowerCase() == 'true' ? 'Oui' : 'Non';
    } else {
      final items = rawValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final cleanItems = <String>[];
      final optionEmojis = <String>[];

      for (final item in items) {
        if (item.contains('|')) {
          final parts = item.split('|');
          cleanItems.add(parts[0].trim());
          if (parts.length > 1) {
            optionEmojis.add(parts[1].trim());
          }
        } else {
          cleanItems.add(item);
        }
      }

      if (cleanItems.isNotEmpty) {
        content = cleanItems.join(', ');
      }
      if (optionEmojis.isNotEmpty) {
        emoji = emoji + optionEmojis.join('');
      }
    }

    return {
      'emoji': emoji,
      'content': content,
    };
  }

  Widget _buildLocationRow({
    required String label,
    required String address,
    required Color iconColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _launchMaps(address),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: iconColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.directions_rounded,
                color: iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    final appleMapsUrl = 'https://maps.apple.com/maps?q=$query';

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
          return;
        }
      }
      
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir l\'application Cartes.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la carte : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCustomFieldRow({
    required String label,
    required String emoji,
    required String content,
    required Color iconColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: emoji.isNotEmpty
                  ? Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    )
                  : Icon(
                      Icons.dashboard_customize_outlined,
                      color: iconColor,
                      size: 14,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  String formatDateTimeRange(TimetreeEvent ev) {
    final start = ev.startDate;
    final end = ev.endDate;
    final startDayStr = formatDetailsDate(start);
    final endDayStr = formatDetailsDate(end);

    if (ev.allDay) {
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        return "$startDayStr (Jour entier)";
      } else {
        return "Du $startDayStr au $endDayStr (Jour entier)";
      }
    } else {
      final startTimeStr = formatFrenchTime(start);
      final endTimeStr = formatFrenchTime(end);
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        return "$startDayStr, de $startTimeStr à $endTimeStr";
      } else {
        return "Du $startDayStr à $startTimeStr\nau $endDayStr à $endTimeStr";
      }
    }
  }

  String getRecurrenceLabel(String rule, DateTime? endDate) {
    String label = 'Aucune';
    switch (rule.toUpperCase()) {
      case 'DAILY':
        label = 'Tous les jours';
        break;
      case 'WEEKLY':
        label = 'Toutes les semaines';
        break;
      case 'MONTHLY':
        label = 'Tous les mois';
        break;
    }
    if (rule.toUpperCase() != 'NONE' && endDate != null) {
      label += " (jusqu'au ${DateFormat('dd/MM/yyyy').format(endDate)})";
    }
    return label;
  }

  String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Brouillon';
      case 'PLANNED':
        return 'Planifié';
      case 'IN_PROGRESS':
        return 'En cours';
      case 'COMPLETED':
        return 'Terminé';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return status;
    }
  }

  String getPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return 'Basse';
      case 'NORMAL':
        return 'Normale';
      case 'HIGH':
        return 'Haute';
      case 'CRITICAL':
        return 'Critique';
      default:
        return priority;
    }
  }

  Widget _buildTagsRow(List<TimetreeTag> tags, Color iconColor, Color textColor) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_offer_rounded, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) {
                Color? chipBg;
                final tagColor = t.color;
                if (tagColor != null && tagColor.isNotEmpty) {
                  final parsedColor = int.tryParse(tagColor);
                  if (parsedColor != null) {
                    chipBg = Color(parsedColor).withValues(alpha: 0.2);
                  }
                }
                final borderCol = chipBg != null && tagColor != null
                    ? Color(int.parse(tagColor)).withValues(alpha: 0.5)
                    : iconColor.withValues(alpha: 0.3);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg ?? iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderCol,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    t.name,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependenciesRow(List<Map<String, dynamic>> dependencies, Color iconColor, Color textColor) {
    if (dependencies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.link_rounded, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dependencies.map((dep) {
                final depTitle = dep['title'] ?? 'Événement';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    "Dépend de: $depTitle",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsListRow(List<TimetreeMember> participants, Color iconColor, Color textColor) {
    if (participants.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.people_alt_outlined, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Participants",
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: participants.map((p) {
                    final fullName = p.fullName;
                    final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.shade300.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.purple.shade300,
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fullName,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
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
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.grey),
              onPressed: _sending ? null : _showAttachmentOptions,
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

  Widget _buildAttachmentBubble(TimetreeMessage msg, bool isMe, Color textColor, bool isDark) {
    final timeStr = DateFormat('HH:mm').format(msg.sentAt);
    final parts = msg.metadata!.split(':');
    final attachmentId = parts.length > 1 ? parts[1] : '';
    final fileName = msg.message.replaceAll('A ajouté la pièce jointe: ', '');
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
                constraints: const BoxConstraints(maxWidth: 240),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.zero,
                  ),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TimetreeAttachmentPreview(
                    attachmentId: attachmentId,
                    fileName: fileName,
                    eventId: widget.event.id,
                  ),
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
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262626) : Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.zero,
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: TimetreeAttachmentPreview(
                              attachmentId: attachmentId,
                              fileName: fileName,
                              eventId: widget.event.id,
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
      await repository.uploadAttachment(widget.event.id, filePath, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier envoyé avec succès !')),
        );
        ref.read(timetreeChatProvider(widget.event.id).notifier).loadInitial();
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

  void _showTraceabilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _EventHistoryDialog(
        eventId: widget.event.id,
        eventTitle: widget.event.nomEvent ?? widget.event.title,
      ),
    );
  }
}

class _EventHistoryDialog extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const _EventHistoryDialog({
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<_EventHistoryDialog> createState() => _EventHistoryDialogState();
}

class _EventHistoryDialogState extends ConsumerState<_EventHistoryDialog> {
  final _searchController = TextEditingController();
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  List<TimetreeAuditLog> _allLogs = [];
  List<TimetreeAuditLog> _filteredLogs = [];
  bool _loading = true;

  final List<String> _actions = ['CREATE', 'UPDATE', 'DELETE', 'UPDATE_VALUES'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(timetreeEventsProviderProvider);
      final logs = await repo.getEventHistory(widget.eventId);
      if (mounted) {
        setState(() {
          _allLogs = logs;
          _loading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        if (_selectedAction != null && log.action.toUpperCase() != _selectedAction!.toUpperCase()) {
          return false;
        }
        if (_startDate != null && log.actionDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null) {
          final endOfDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (log.actionDate.isAfter(endOfDate)) {
            return false;
          }
        }
        if (search.isNotEmpty) {
          final user = (log.username ?? '').toLowerCase();
          final details = (log.details ?? '').toLowerCase();
          if (!user.contains(search) && !details.contains(search)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedAction = null;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _applyFilters();
    }
  }

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'UPDATE_VALUES':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Historique : ${widget.eventTitle}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Filters Section
            ExpansionTile(
              leading: Icon(Icons.filter_alt_outlined, color: theme.colorScheme.primary, size: 20),
              title: const Text('Filtres de recherche', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Rechercher',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedAction,
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          labelText: 'Action',
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes', style: TextStyle(fontSize: 13))),
                          ..._actions.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedAction = val);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          _startDate == null ? 'Début' : DateFormat('dd/MM/yyyy').format(_startDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _selectStartDate(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          _endDate == null ? 'Fin' : DateFormat('dd/MM/yyyy').format(_endDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _selectEndDate(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Réinitialiser', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Logs List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLogs.isEmpty
                      ? const Center(child: Text('Aucune trace d\'activité.', style: TextStyle(fontStyle: FontStyle.italic)))
                      : ListView.builder(
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final logItem = _filteredLogs[index];
                            final fmtDate = DateFormat('dd/MM/yyyy HH:mm').format(logItem.actionDate);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  width: 0.8,
                                ),
                              ),
                              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _actionColor(logItem.action).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            logItem.action,
                                            style: TextStyle(
                                              color: _actionColor(logItem.action),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            logItem.details ?? '${logItem.action} ${logItem.entityType}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_outline_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(logItem.username ?? 'Système', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(fmtDate, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.computer_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(logItem.ipAddress ?? '0.0.0.0', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

