import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_chat_tab.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_attachments_tab.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class TimetreeEventDetailsDialog extends ConsumerStatefulWidget {
  final TimetreeEvent event;
  final List<TimetreeGroup> groups;
  final VoidCallback onRefresh;
  final VoidCallback onEditClicked;

  const TimetreeEventDetailsDialog({
    super.key,
    required this.event,
    required this.groups,
    required this.onRefresh,
    required this.onEditClicked,
  });

  @override
  ConsumerState<TimetreeEventDetailsDialog> createState() => _TimetreeEventDetailsDialogState();
}

class _TimetreeEventDetailsDialogState extends ConsumerState<TimetreeEventDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<TimetreeCustomField> _customFields = [];
  Map<String, String> _customFieldValues = {};
  bool _loadingFields = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomFieldsAndValues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomFieldsAndValues() async {
    setState(() => _loadingFields = true);
    try {
      final repo = ref.read(timetreeCustomFieldsRepositoryProvider);
      
      final fields = await repo.getEventFields(
        groupId: widget.event.groupId,
        calendarId: widget.event.calendarId,
        eventId: widget.event.id,
      );

      final values = await repo.getCustomFieldValues('EVENT', widget.event.id);
      final Map<String, String> valuesMap = {};
      for (final val in values) {
        if (val.value != null) {
          valuesMap[val.field.id] = val.value!;
        }
      }

      setState(() {
        _customFields = fields;
        _customFieldValues = valuesMap;
        _loadingFields = false;
      });
    } catch (_) {
      setState(() => _loadingFields = false);
    }
  }

  String _formatFieldValue(TimetreeCustomField field, String val) {
    if (field.fieldType == 'BOOLEAN') {
      return val.toLowerCase() == 'true' ? 'Oui' : 'Non';
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ev = widget.event;
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toUpperCase() ?? 'MEMBER';

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      title: Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.fromLTRB(20, 16, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ev.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: (!ev.locked || (userRole == 'ADMIN' || userRole == 'CHEF'))
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
                  tooltip: (!ev.locked || (userRole == 'ADMIN' || userRole == 'CHEF'))
                      ? 'Modifier'
                      : 'Verrouillé (Admin/Chef uniquement)',
                  onPressed: (!ev.locked || (userRole == 'ADMIN' || userRole == 'CHEF'))
                      ? () {
                          Navigator.pop(context);
                          widget.onEditClicked();
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cet événement est verrouillé et ne peut pas être modifié par un membre.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded), text: 'Détails'),
                Tab(icon: Icon(Icons.forum_outlined), text: 'Discussion'),
                Tab(icon: Icon(Icons.share_outlined), text: 'Partage'),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 600,
        height: 480,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(theme),
            TimetreeChatTab(eventId: ev.id),
            TimetreeAttachmentsTab(eventId: ev.id),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(ThemeData theme) {
    final ev = widget.event;
    final startStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(ev.startDate);
    final endStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(ev.endDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ev.description != null && ev.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              ev.description!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Début', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(startStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fin', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(endStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          if (ev.allDay) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.today_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                const Text('Toute la journée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 16),

          if (ev.groupName != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Groupe', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(ev.groupName!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calendrier', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(ev.calendarName ?? 'Aucun', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (ev.recurrenceRule != 'NONE') ...[
            Text('Répétition', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              ev.recurrenceRule == 'DAILY'
                  ? 'Tous les jours'
                  : ev.recurrenceRule == 'WEEKLY'
                      ? 'Toutes les semaines'
                      : 'Tous les mois',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
          ],

          // Workflow status and priority
          Row(
            children: [
              _buildStatusBadge(theme, ev.status),
              const SizedBox(width: 8),
              _buildPriorityBadge(theme, ev.priority),
              if (ev.locked) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Verrouillé',
                  child: Icon(Icons.lock, color: Colors.orange, size: 20),
                ),
              ],
              if (ev.isPrivate) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Privé',
                  child: Icon(Icons.visibility_off, color: Colors.purple, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Reusable tags
          if (ev.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ev.tags.map((tag) {
                Color tagColor = Colors.blueGrey;
                if (tag.color != null && tag.color!.isNotEmpty) {
                  try {
                    tagColor = Color(int.parse(tag.color!.replaceAll('#', 'FF'), radix: 16));
                  } catch (_) {
                    try {
                      tagColor = Color(int.parse(tag.color!));
                    } catch (_) {}
                  }
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag.name,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Event dependencies
          if (ev.dependencies.isNotEmpty) ...[
            Text(
              'Dépendances',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ev.dependencies.map((dep) {
                final String depTitle = dep['title'] ?? 'Événement #${dep['id']}';
                final String depStatus = dep['status'] ?? 'PLANNED';
                final bool isCompleted = depStatus == 'COMPLETED';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                        size: 16,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          depTitle,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? '(Terminé)' : '(Non terminé)',
                        style: TextStyle(fontSize: 11, color: isCompleted ? Colors.green : Colors.orange),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Reminders checklist
          if (ev.reminders.isNotEmpty) ...[
            Text(
              'Rappels',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ev.reminders.map((rem) {
                final timeStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(rem);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Participants (${ev.participants.length})',
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (ev.participants.isEmpty)
            const Text('Aucun participant affecté à cet événement.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ev.participants.map((p) {
                final initials = p.fullName.isNotEmpty ? p.fullName.substring(0, 2).toUpperCase() : '?';
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Text(initials, style: const TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                  label: Text(p.fullName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Champs Personnalisés',
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_loadingFields)
            const Center(child: CircularProgressIndicator())
          else if (_customFields.isEmpty)
            const Text('Aucun champ personnalisé défini.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customFields.length,
              itemBuilder: (context, idx) {
                final field = _customFields[idx];
                final value = _customFieldValues[field.id] ?? field.defaultValue ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          field.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          value.isEmpty ? 'Non renseigné' : _formatFieldValue(field, value),
                          style: TextStyle(
                            fontSize: 13,
                            color: value.isEmpty ? Colors.grey : Colors.black,
                            fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'DRAFT':
        color = Colors.grey;
        label = 'Brouillon';
        break;
      case 'PLANNED':
        color = Colors.blue;
        label = 'Planifié';
        break;
      case 'IN_PROGRESS':
        color = Colors.orange;
        label = 'En cours';
        break;
      case 'COMPLETED':
        color = Colors.green;
        label = 'Terminé';
        break;
      case 'CANCELLED':
        color = Colors.red;
        label = 'Annulé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriorityBadge(ThemeData theme, String priority) {
    Color color;
    String label;
    switch (priority.toUpperCase()) {
      case 'LOW':
        color = Colors.grey;
        label = 'Priorité basse';
        break;
      case 'NORMAL':
        color = Colors.teal;
        label = 'Priorité normale';
        break;
      case 'HIGH':
        color = Colors.orange;
        label = 'Priorité haute';
        break;
      case 'CRITICAL':
        color = Colors.red;
        label = 'Priorité critique';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
