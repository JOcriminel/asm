import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_notifications_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(timetreeNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () {
              context.push('/notifications/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () async {
              try {
                await ref.read(timetreeNotificationsProvider.notifier).markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Toutes les notifications sont marquées comme lues')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(timetreeNotificationsProvider.notifier).loadNotifications(),
        child: asyncNotifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Impossible de charger les notifications : $error'),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune notification',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Dismissible(
                  key: Key('notif-${notif.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(timetreeNotificationsProvider.notifier).deleteNotification(notif.id);
                  },
                  child: _NotificationCard(notification: notif),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final TimetreeNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    IconData iconData = Icons.notifications_none;
    Color iconColor = theme.colorScheme.primary;

    switch (notification.type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        iconData = Icons.campaign;
        iconColor = Colors.orange;
        break;
      case 'MENTION':
        iconData = Icons.alternate_email;
        iconColor = Colors.blue;
        break;
      case 'REMINDER':
        iconData = Icons.alarm;
        iconColor = Colors.purple;
        break;
      case 'NEW_MESSAGE':
      case 'CHAT':
        iconData = Icons.chat_bubble_outline;
        iconColor = Colors.green;
        break;
    }

    final formattedDate = _formatDate(notification.createdAt);

    return InkWell(
      onTap: () {
        if (isUnread) {
          ref.read(timetreeNotificationsProvider.notifier).markRead(notification.id);
        }
        _showDetailsDialog(context, notification);
      },
      child: Container(
        color: isUnread ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return "Il y a ${difference.inMinutes} min";
      } else if (difference.inHours < 24) {
        return "Il y a ${difference.inHours} h";
      } else {
        return DateFormat('dd/MM HH:mm').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  void _showDetailsDialog(BuildContext context, TimetreeNotification notif) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(notif.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Reçu le: ${DateFormat('dd MMMM yyyy à HH:mm').format(notif.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
