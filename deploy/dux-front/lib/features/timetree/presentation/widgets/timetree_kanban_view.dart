import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';

class TimetreeKanbanView extends ConsumerWidget {
  final List<TimetreeEvent> events;
  final List<TimetreeCalendar> calendars;
  final Function(TimetreeEvent) onTapEvent;

  const TimetreeKanbanView({
    super.key,
    required this.events,
    required this.calendars,
    required this.onTapEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter events into status categories
    final todoEvents = events.where((e) => e.status == 'PLANNED' || e.status == 'DRAFT').toList();
    final inProgressEvents = events.where((e) => e.status == 'IN_PROGRESS').toList();
    final completedEvents = events.where((e) => e.status == 'COMPLETED').toList();

    return Container(
      color: isDark ? Colors.black : Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKanbanColumn(
              context: context,
              ref: ref,
              title: "À FAIRE",
              statusKey: "PLANNED",
              color: Colors.blueAccent,
              events: todoEvents,
              isDark: isDark,
            ),
            _buildKanbanColumn(
              context: context,
              ref: ref,
              title: "EN COURS",
              statusKey: "IN_PROGRESS",
              color: Colors.orangeAccent,
              events: inProgressEvents,
              isDark: isDark,
            ),
            _buildKanbanColumn(
              context: context,
              ref: ref,
              title: "TERMINÉ",
              statusKey: "COMPLETED",
              color: Colors.greenAccent,
              events: completedEvents,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String statusKey,
    required Color color,
    required List<TimetreeEvent> events,
    required bool isDark,
  }) {
    final width = MediaQuery.of(context).size.width * 0.82;

    return DragTarget<TimetreeEvent>(
      onWillAcceptWithDetails: (details) => details.data.status != statusKey,
      onAcceptWithDetails: (details) async {
        final event = details.data;
        try {
          // Trigger the update via Riverpod notifier
          await ref.read(timetreeEventsProvider.notifier).updateEvent(
                event.id,
                event.copyWith(status: statusKey),
              );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut de "${event.title}" mis à jour avec succès.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du changement de statut : $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;

        return Container(
          width: width,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isOver
                ? color.withValues(alpha: 0.08)
                : (isDark ? Colors.grey[900] : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOver
                  ? color
                  : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
              width: isOver ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[150]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${events.length}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? color : color.darken(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tasks List
              Flexible(
                child: events.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 36,
                                color: isDark ? Colors.grey[750] : Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun événement',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildKanbanCard(context, event, isDark, width);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanCard(BuildContext context, TimetreeEvent event, bool isDark, double width) {
    final theme = Theme.of(context);
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // Priority color helpers
    Color priorityColor;
    String priorityLabel;
    switch (event.priority) {
      case 'CRITICAL':
        priorityColor = Colors.redAccent;
        priorityLabel = 'Urgente';
        break;
      case 'HIGH':
        priorityColor = Colors.deepOrangeAccent;
        priorityLabel = 'Haute';
        break;
      case 'LOW':
        priorityColor = Colors.teal;
        priorityLabel = 'Basse';
        break;
      case 'NORMAL':
      default:
        priorityColor = Colors.blueGrey;
        priorityLabel = 'Normale';
        break;
    }

    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM');
    final String timeStr = event.allDay
        ? "Toute la journée"
        : "${timeFormatter.format(event.startDate)} - ${timeFormatter.format(event.endDate)}";
    final String dateStr = dateFormatter.format(event.startDate);

    final cardWidget = Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTapEvent(event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar tag & Priority badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: event.color != null
                          ? _parseColor(event.color!).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.calendarName ?? 'Général',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: event.color != null
                            ? _parseColor(event.color!)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                event.nomEvent ?? event.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description preview (if exists)
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              Divider(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                height: 1,
              ),
              const SizedBox(height: 10),

              // Time, Date & participants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: subTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$dateStr • $timeStr",
                        style: TextStyle(
                          fontSize: 11,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Participants avatars
                  if (event.participants.isNotEmpty)
                    SizedBox(
                      height: 20,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: List.generate(
                          event.participants.length > 3 ? 3 : event.participants.length,
                          (i) {
                            final p = event.participants[i];
                            return Container(
                              margin: EdgeInsets.only(right: i * 14.0),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  p.fullName.isNotEmpty
                                      ? p.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return LongPressDraggable<TimetreeEvent>(
      data: event,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width * 0.95,
          child: cardWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: cardWidget,
      ),
      child: cardWidget,
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexString = colorString.replaceAll('#', '');
      if (hexString.length == 6) {
        return Color(int.parse("FF$hexString", radix: 16));
      } else if (hexString.length == 8) {
        return Color(int.parse(hexString, radix: 16));
      }
    } catch (_) {}
    return Colors.blue;
  }
}

// Extension to darken colors for text readability
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
