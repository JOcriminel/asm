import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_notifications_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_events_repository.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_event_details_dialog.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';

class TimetreeNotificationCenter extends ConsumerWidget {
  const TimetreeNotificationCenter({super.key});

  Future<void> _handleNotificationClick(BuildContext context, WidgetRef ref, TimetreeNotification notification) async {
    // 1. Mark as read
    if (!notification.isRead) {
      await ref.read(timetreeNotificationsProvider.notifier).markRead(notification.id);
    }

    if (!context.mounted) return;

    // Show loading spinner
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Resolve Event ID
      final eventId = await ref.read(timetreeNotificationsProvider.notifier).resolveEventId(
        notification.entityType,
        notification.entityId,
      );

      // 3. Fetch Event Details
      final event = await ref.read(timetreeEventsRepositoryProvider).getEvent(eventId);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading spinner
      Navigator.pop(context); // Close notification dialog/drawer

      // 4. Open tabbed event details view
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final groups = ref.read(timetreeGroupsProvider).value ?? [];
          return TimetreeEventDetailsDialog(
            event: event,
            groups: groups,
            onRefresh: () {
              ref.read(timetreeEventsProvider.notifier).loadEvents();
            },
            onEditClicked: () {
              // Open edit dialog via calendar screen logic if necessary
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir l\'événement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(timetreeNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre de Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(timetreeNotificationsProvider.notifier).markAllRead(),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Tout marquer lu'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = list[index];
              final timeStr = DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(n.createdAt);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.isRead
                      ? Colors.grey.shade300
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    n.type == 'NEW_MESSAGE'
                        ? Icons.chat_bubble_outline_rounded
                        : n.type == 'NEW_ATTACHMENT'
                            ? Icons.attach_file_rounded
                            : Icons.notifications_none_rounded,
                    color: n.isRead ? Colors.grey.shade600 : theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.content, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(timeStr, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                  ],
                ),
                trailing: !n.isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () => _handleNotificationClick(context, ref, n),
              );
            },
          );
        },
      ),
    );
  }
}
