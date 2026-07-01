import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_notifications_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final List<Map<String, dynamic>> _snoozeOptions = [
    {'label': '2 Heures', 'duration': const Duration(hours: 2)},
    {'label': '8 Heures', 'duration': const Duration(hours: 8)},
    {'label': '1 Jour', 'duration': const Duration(days: 1)},
    {'label': '7 Jours (Max)', 'duration': const Duration(days: 7)},
  ];

  Map<String, dynamic>? _selectedSnoozeOption;
  bool _isSnoozed = false;

  @override
  Widget build(BuildContext context) {
    final asyncPrefs = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de Notification'),
      ),
      body: asyncPrefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erreur de chargement: $err'),
        ),
        data: (prefs) {
          final now = DateTime.now();
          final isMutedNow = prefs.snoozeUntil != null &&
              prefs.snoozeUntil!.isAfter(now);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Canaux de Notification',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Activer les alertes Push'),
                      subtitle: const Text('Alertes instantanées sur votre téléphone'),
                      value: prefs.pushEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(pushEnabled: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mes propres actions'),
                      subtitle: const Text('M\'avertir de mes propres actions'),
                      value: prefs.notifyOwnActions,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(notifyOwnActions: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Sourdine sauf événements suivis'),
                      subtitle: const Text('Muter toutes les alertes sauf si l\'événement a des rappels'),
                      value: prefs.muteAllExceptSpecific,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(muteAllExceptSpecific: val));
                        if (val) {
                          _showFollowEventsBottomSheet(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Alertes par Événements',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Mentions (@moi)'),
                      value: prefs.mentionsEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(mentionsEnabled: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Rappels d\'événements'),
                      value: prefs.remindersEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(remindersEnabled: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Messages du Chat'),
                      value: prefs.chatEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(chatEnabled: val));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Sons et Vibrations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Sons'),
                      value: prefs.soundEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(soundEnabled: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Vibrations'),
                      value: prefs.vibrationEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences(prefs.copyWith(vibrationEnabled: val));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ne pas déranger (Mute)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Snoozer temporairement toutes les alertes',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: isMutedNow || _isSnoozed,
                            onChanged: (val) {
                              setState(() {
                                _isSnoozed = val;
                                if (!val) {
                                  _selectedSnoozeOption = null;
                                  // Disable snooze on backend
                                  ref
                                      .read(notificationPreferencesProvider.notifier)
                                      .updatePreferences(
                                        prefs.copyWith(resetSnooze: true),
                                      );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (isMutedNow) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_off, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Snooze actif jusqu\'au:\n${DateFormat('dd MMMM yyyy à HH:mm').format(prefs.snoozeUntil!)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  ref
                                      .read(notificationPreferencesProvider.notifier)
                                      .updatePreferences(
                                        prefs.copyWith(resetSnooze: true),
                                      );
                                  setState(() {
                                    _isSnoozed = false;
                                  });
                                },
                                child: const Text('Désactiver'),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_isSnoozed) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Choisissez la durée du snooze (Max 7 jours) :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _snoozeOptions.map((opt) {
                            final isSelected = _selectedSnoozeOption == opt;
                            return ChoiceChip(
                              label: Text(opt['label'] as String),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSnoozeOption = selected ? opt : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (_selectedSnoozeOption != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                final duration = _selectedSnoozeOption!['duration'] as Duration;
                                final snoozeUntilDate = now.add(duration);
                                ref
                                    .read(notificationPreferencesProvider.notifier)
                                    .updatePreferences(
                                      prefs.copyWith(snoozeUntil: snoozeUntilDate),
                                    );
                                setState(() {
                                  _isSnoozed = false;
                                  _selectedSnoozeOption = null;
                                });
                              },
                              child: const Text('Confirmer le Snooze'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFollowEventsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final eventsAsync = ref.watch(timetreeEventsProvider);
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Text(
                              'Événements à suivre',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sélectionnez les événements pour lesquels vous souhaitez continuer à recevoir des notifications.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      
                      // List
                      Expanded(
                        child: eventsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Erreur: $err')),
                          data: (events) {
                            if (events.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'Aucun événement planifié trouvé.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            // Sort by date
                            final sortedEvents = List<TimetreeEvent>.from(events)
                              ..sort((a, b) => a.startDate.compareTo(b.startDate));

                            return ListView.builder(
                              controller: scrollController,
                              itemCount: sortedEvents.length,
                              itemBuilder: (context, index) {
                                final event = sortedEvents[index];
                                final hasReminders = event.reminders.isNotEmpty;
                                final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'fr').format(event.startDate);

                                return CheckboxListTile(
                                  title: Text(
                                    event.nomEvent ?? event.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '$dateStr\nAgenda: ${event.calendarName ?? "Général"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  isThreeLine: true,
                                  value: hasReminders,
                                  onChanged: (val) async {
                                    try {
                                      List<DateTime> newReminders = [];
                                      if (val == true) {
                                        // Default reminder 15 mins before
                                        newReminders = [
                                          event.startDate.subtract(const Duration(minutes: 15))
                                        ];
                                      }

                                      await ref
                                          .read(timetreeEventsProvider.notifier)
                                          .updateEvent(
                                            event.id,
                                            event.copyWith(reminders: newReminders),
                                          );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur lors de la mise à jour: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
