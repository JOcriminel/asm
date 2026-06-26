import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_events_repository.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_chat_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_notifications_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';
import 'package:dux_front/features/timetree/presentation/widgets/dynamic_event_form_renderer.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_event_details_dialog.dart';
import 'package:dux_front/features/timetree/presentation/widgets/timetree_notification_center.dart';
import 'package:dux_front/features/timetree/presentation/widgets/mes_agendas_bottom_sheet.dart';
import 'package:dux_front/features/timetree/presentation/screens/membership_calendars_screen.dart';
import 'package:go_router/go_router.dart';

String _getCalendarCover(TimetreeCalendar cal) {
  if (cal.description.contains('|[cover:')) {
    final parts = cal.description.split('|[cover:');
    if (parts.length > 1) {
      return parts[1].replaceAll(']', '').trim();
    }
  }
  return '';
}

class TimetreeCalendarViewScreen extends ConsumerStatefulWidget {
  const TimetreeCalendarViewScreen({super.key});

  @override
  ConsumerState<TimetreeCalendarViewScreen> createState() => _TimetreeCalendarViewScreenState();
}

class _TimetreeCalendarViewScreenState extends ConsumerState<TimetreeCalendarViewScreen> {
  // Static Palette for Calendar/Group Colors
  final List<Color> _colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  Color _getCalendarColor(String calendarId, List<TimetreeCalendar> calendars) {
    final idx = calendars.indexWhere((c) => c.id == calendarId);
    if (idx != -1) {
      final hex = calendars[idx].color.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return _colorPalette[idx % _colorPalette.length];
      }
    }
    return Colors.grey;
  }

  void _navigateCalendar(int direction) {
    final mode = ref.read(calendarViewModeProvider);
    final date = ref.read(currentCalendarDateProvider);
    if (mode == 'MONTH') {
      ref.read(currentCalendarDateProvider.notifier).state = DateTime(date.year, date.month + direction, 1);
    } else if (mode == 'WEEK') {
      ref.read(currentCalendarDateProvider.notifier).state = date.add(Duration(days: 7 * direction));
    } else {
      ref.read(currentCalendarDateProvider.notifier).state = date.add(Duration(days: direction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role.toUpperCase() ?? 'MEMBER';
    final username = user?.username ?? '';

    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final eventsAsync = ref.watch(expandedEventsProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final focusedDate = ref.watch(currentCalendarDateProvider);
    final selectedCalendarIds = ref.watch(selectedCalendarIdsProvider);
    ref.watch(timetreeChatUnreadCountsProvider);

    final allCalendars = calendarsAsync.value ?? [];
    Color themeSeedColor = Colors.blue;
    if (allCalendars.isNotEmpty) {
      final activeCalendarId = selectedCalendarIds.isNotEmpty ? selectedCalendarIds.first : allCalendars.first.id;
      final activeCalendar = allCalendars.firstWhere((c) => c.id == activeCalendarId, orElse: () => allCalendars.first);
      try {
        final cleanHex = activeCalendar.color.replaceAll('#', '');
        themeSeedColor = Color(int.parse('FF$cleanHex', radix: 16));
      } catch (_) {}
    }

    final dateStr = DateFormat('MMMM yyyy', 'fr_FR').format(focusedDate);
    final formattedTitle = dateStr.isNotEmpty ? dateStr[0].toUpperCase() + dateStr.substring(1) : '';

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeSeedColor,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark ? Colors.black : null,
        drawer: const DuxDrawer(),
        appBar: AppBar(
          backgroundColor: theme.brightness == Brightness.dark ? Colors.black : null,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: InkWell(
            onTap: () => _selectMonthYear(context, focusedDate),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTitle.toLowerCase(),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Choisir la vue',
              initialValue: viewMode,
              onSelected: (val) {
                ref.read(calendarViewModeProvider.notifier).state = val;
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'MONTH',
                  child: Text('Mois'),
                ),
                const PopupMenuItem(
                  value: 'WEEK',
                  child: Text('Semaine'),
                ),
                const PopupMenuItem(
                  value: 'DAY',
                  child: Text('Jour'),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'refresh') {
                  ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
                  ref.read(timetreeEventsProvider.notifier).loadEvents();
                  ref.read(timetreeChatUnreadCountsProvider.notifier).loadUnreadCounts();
                } else if (val == 'export') {
                  _showExportBottomSheet(context);
                } else if (val == 'notifications') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const TimetreeNotificationCenter(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Rafraîchir'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download_rounded),
                    title: Text('Exporter'),
                  ),
                ),
                PopupMenuItem(
                  value: 'notifications',
                  child: Consumer(
                    builder: (context, ref, child) {
                      final unreadNotifs = ref.watch(timetreeUnreadNotificationsCountProvider);
                      return ListTile(
                        leading: Badge(
                          isLabelVisible: unreadNotifs > 0,
                          label: Text('$unreadNotifs'),
                          child: const Icon(Icons.notifications_rounded),
                        ),
                        title: const Text('Notifications'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: calendarsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Erreur de chargement: $err'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.read(timetreeCalendarsProvider.notifier).loadCalendars(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (allCals) {
            // Filter calendars based on RBAC rules:
            // Admin: full access
            // Chef: managed calendars
            // Member: assigned calendars
            final List<TimetreeCalendar> calendars;
            if (role == 'ADMIN' || role == 'ADMINISTRATEUR') {
              calendars = allCals;
            } else {
              calendars = allCals.where((c) => c.members.any((m) => m.username == username)).toList();
            }

            if (calendars.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun agenda affecté.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Veuillez contacter un administrateur pour vous affecter à un agenda.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Populate default calendar filters on first run
            if (selectedCalendarIds.isEmpty && calendars.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedCalendarIdsProvider.notifier).setAll(
                      calendars.map((c) => c.id).toSet(),
                    );
              });
            }

            final calendarGrid = eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur événements: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
              data: (events) {
                switch (viewMode) {
                  case 'WEEK':
                    return _buildWeekView(context, events, calendars);
                  case 'DAY':
                    return _buildDayView(context, events, calendars);
                  case 'MONTH':
                  default:
                    return _buildMonthView(context, events, calendars);
                }
              },
            );

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const MesAgendasBottomSheet(),
                  );
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -300) {
                    // Swipe left -> Next Month
                    _navigateCalendar(1);
                  } else if (details.primaryVelocity! > 300) {
                    // Swipe right -> Previous Month
                    _navigateCalendar(-1);
                  }
                }
              },
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHorizontalAgendasSelector(calendars),
                      Expanded(child: calendarGrid),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFEBEBEB),
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                      shape: const CircleBorder(),
                      onPressed: () => _showEventDialog(null, calendars),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

      ),
    );
  }

  // Header Switcher
  Widget _buildCalendarHeader(DateTime date, String mode, List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    String title = '';
    if (mode == 'MONTH') {
      title = DateFormat('MMMM yyyy', 'fr_FR').format(date);
    } else if (mode == 'WEEK') {
      final weekday = date.weekday;
      final weekStart = date.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      title = "S${DateFormat('w', 'fr_FR').format(date)}: ${DateFormat('dd MMM', 'fr_FR').format(weekStart)} - ${DateFormat('dd MMM yyyy', 'fr_FR').format(weekEnd)}";
    } else {
      title = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
    }

    // Capitalize first letter of title
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _navigateCalendar(-1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _navigateCalendar(1),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              // Add event button
              IconButton(
                icon: const Icon(Icons.add_box_rounded, color: Colors.blueAccent),
                tooltip: 'Ajouter un événement',
                onPressed: () => _showEventDialog(null, calendars),
              ),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MONTH', label: Text('Mois')),
                  ButtonSegment(value: 'WEEK', label: Text('Semaine')),
                  ButtonSegment(value: 'DAY', label: Text('Jour')),
                ],
                selected: {mode},
                onSelectionChanged: (newSelection) {
                  ref.read(calendarViewModeProvider.notifier).state = newSelection.first;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }



  // Month Grid View with Multi-Day Spanning Bars
  Widget _buildMonthView(BuildContext context, List<TimetreeEvent> events, List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    final focusedDate = ref.watch(currentCalendarDateProvider);
    final int firstWeekday = DateTime(focusedDate.year, focusedDate.month, 1).weekday; // 1 = Monday, 7 = Sunday

    final daysOfWeek = ['LUN.', 'MAR.', 'MER.', 'JEU.', 'VEN.', 'SAM.', 'DIM.'];

    // Generate dates for all 42 cells (6 weeks)
    final List<DateTime> cellDates = List.generate(42, (index) {
      final cellDayNumber = index - firstWeekday + 2;
      return DateTime(focusedDate.year, focusedDate.month, cellDayNumber);
    });

    // Map of day index (0..41) -> list of events in slots
    final List<List<TimetreeEvent?>> cellSlots = List.generate(42, (_) => []);
    // Map of day index (0..41) -> total event count active on that day
    final List<int> cellEventCounts = List.generate(42, (_) => 0);

    // Get all events active in this 42-day range
    final List<TimetreeEvent> activeEvents = [];
    final rangeStart = DateTime(cellDates.first.year, cellDates.first.month, cellDates.first.day, 0, 0, 0);
    final rangeEnd = DateTime(cellDates.last.year, cellDates.last.month, cellDates.last.day, 23, 59, 59);
    for (final e in events) {
      if (e.startDate.isBefore(rangeEnd) && e.endDate.isAfter(rangeStart)) {
        activeEvents.add(e);
      }
    }

    // Sort active events:
    // 1. Duration within this 42-day range (descending)
    // 2. Start date (ascending)
    activeEvents.sort((a, b) {
      final aStart = a.startDate.isBefore(rangeStart) ? rangeStart : a.startDate;
      final aEnd = a.endDate.isAfter(rangeEnd) ? rangeEnd : a.endDate;
      final bStart = b.startDate.isBefore(rangeStart) ? rangeStart : b.startDate;
      final bEnd = b.endDate.isAfter(rangeEnd) ? rangeEnd : b.endDate;
      final aDur = aEnd.difference(aStart).inDays;
      final bDur = bEnd.difference(bStart).inDays;
      if (aDur != bDur) {
        return bDur.compareTo(aDur);
      }
      return a.startDate.compareTo(b.startDate);
    });

    // Allocate slots globally across 42 days
    for (final event in activeEvents) {
      final List<bool> activeDays = List.generate(42, (d) {
        final day = cellDates[d];
        final cellStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
        final cellEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
        return event.startDate.isBefore(cellEnd) && event.endDate.isAfter(cellStart);
      });

      int slotIdx = 0;
      while (true) {
        bool slotFree = true;
        for (int d = 0; d < 42; d++) {
          if (activeDays[d]) {
            if (slotIdx < cellSlots[d].length && cellSlots[d][slotIdx] != null) {
              slotFree = false;
              break;
            }
          }
        }
        if (slotFree) break;
        slotIdx++;
      }

      // Fill slots
      for (int d = 0; d < 42; d++) {
        if (activeDays[d]) {
          while (cellSlots[d].length <= slotIdx) {
            cellSlots[d].add(null);
          }
          cellSlots[d][slotIdx] = event;
        }
      }
    }

    // Compute total event count active on each day
    for (int d = 0; d < 42; d++) {
      int count = 0;
      final day = cellDates[d];
      final cellStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
      final cellEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
      for (final e in events) {
        if (e.startDate.isBefore(cellEnd) && e.endDate.isAfter(cellStart)) {
          count++;
        }
      }
      cellEventCounts[d] = count;
    }

    return Column(
      children: [
        // Days of week header
        Container(
          color: theme.brightness == Brightness.dark ? Colors.black : theme.colorScheme.surfaceContainer,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: daysOfWeek.map((d) {
              final isSunday = d == 'DIM.';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSunday 
                          ? Colors.red 
                          : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]),
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Month days grid (6 weeks = 42 cells)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.black : null,
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
                  width: 0.5,
                ),
                left: BorderSide(
                  color: theme.brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.6,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final cellDate = cellDates[index];
                final cellDayNumber = cellDate.day;
                final isCurrentMonth = cellDate.month == focusedDate.month;

                final dayEvents = events.where((e) {
                  final start = e.startDate;
                  final end = e.endDate;
                  final cellStart = DateTime(cellDate.year, cellDate.month, cellDate.day, 0, 0, 0);
                  final cellEnd = DateTime(cellDate.year, cellDate.month, cellDate.day, 23, 59, 59);
                  return start.isBefore(cellEnd) && end.isAfter(cellStart);
                }).toList();

                // Highlight current date
                final now = DateTime.now();
                final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;

                final dayColor = isToday
                    ? theme.colorScheme.primary
                    : (cellDate.weekday == 7
                        ? Colors.red
                        : (isCurrentMonth
                            ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87)
                            : (theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400])));

                final cellBgColor = isToday
                    ? (theme.brightness == Brightness.dark ? Colors.blue.withOpacity(0.1) : theme.colorScheme.primary.withValues(alpha: 0.15))
                    : (theme.brightness == Brightness.dark ? Colors.black : theme.colorScheme.surfaceContainer);

                final borderSideColor = theme.brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!;

                return InkWell(
                  onTap: () => _showDayEventsBottomSheet(context, cellDate, dayEvents, calendars),
                  child: Container(
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: cellBgColor,
                      border: Border(
                        bottom: BorderSide(color: borderSideColor, width: 0.5),
                        right: BorderSide(color: borderSideColor, width: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                            child: Text(
                              '$cellDayNumber',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                fontSize: 10,
                                color: dayColor,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cellSlots[index].length > 4 ? 5 : cellSlots[index].length,
                            itemBuilder: (context, idx) {
                              if (idx == 4 && cellEventCounts[index] > 5) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '+${cellEventCounts[index] - 4} de plus',
                                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, color: Colors.blueAccent),
                                    ),
                                  ),
                                );
                              }

                              final event = cellSlots[index][idx];
                              if (event == null) {
                                return const SizedBox(height: 14);
                              }

                              final color = event.color != null && event.color!.isNotEmpty
                                  ? Color(int.tryParse(event.color!) ?? Colors.blue.value)
                                  : _getCalendarColor(event.calendarId, calendars);

                              final unreadCounts = ref.watch(timetreeChatUnreadCountsProvider);
                              final unreadCount = unreadCounts[event.id.toString()] ?? 0;

                              // Determine if this is the start cell for this event in this week
                              final int weekStartIdx = (index ~/ 7) * 7;
                              final bool isStartCell = (index == weekStartIdx) || 
                                  (index > weekStartIdx && (cellSlots[index - 1].length <= idx || cellSlots[index - 1][idx]?.id != event.id));

                              // Determine if this is the end cell for this event in this week
                              final int weekEndIdx = weekStartIdx + 6;
                              final bool isEndCell = (index == weekEndIdx) || 
                                  (index < 41 && (cellSlots[index + 1].length <= idx || cellSlots[index + 1][idx]?.id != event.id));

                              final double marginLeft = isStartCell ? 2.0 : 0.0;
                              final double marginRight = isEndCell ? 2.0 : 0.0;

                              final borderRadius = BorderRadius.only(
                                topLeft: isStartCell ? const Radius.circular(4) : Radius.zero,
                                bottomLeft: isStartCell ? const Radius.circular(4) : Radius.zero,
                                topRight: isEndCell ? const Radius.circular(4) : Radius.zero,
                                bottomRight: isEndCell ? const Radius.circular(4) : Radius.zero,
                              );

                              final bool isSpanning = event.endDate.difference(event.startDate).inHours > 24;
                              final bool isSpanningOrAllDay = event.allDay || isSpanning;

                              final chipBgColor = isSpanningOrAllDay ? color : color.withValues(alpha: 0.15);
                              final chipTextColor = isSpanningOrAllDay ? Colors.white : color;

                              final chip = Container(
                                margin: EdgeInsets.only(
                                  left: marginLeft,
                                  right: marginRight,
                                  top: 1,
                                  bottom: 1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: chipBgColor,
                                  borderRadius: borderRadius,
                                ),
                                height: 14,
                                child: isStartCell
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event.title,
                                              style: TextStyle(
                                                fontSize: 8.2, 
                                                color: chipTextColor, 
                                                fontWeight: isSpanningOrAllDay ? FontWeight.bold : FontWeight.w600,
                                                letterSpacing: -0.3,
                                                height: 1.0,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          if (unreadCount > 0)
                                            Container(
                                              margin: const EdgeInsets.only(left: 2),
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              );

                              return InkWell(
                                onTap: () => _showDayEventsBottomSheet(context, cellDate, dayEvents, calendars),
                                child: chip,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showDayEventsBottomSheet(BuildContext context, DateTime date, List<TimetreeEvent> dayEvents, List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    final capitalizedDateStr = dateStr[0].toUpperCase() + dateStr.substring(1);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          capitalizedDateStr,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEventDialog(null, calendars, initialDate: date);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (dayEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Center(
                      child: Text(
                        'Aucun événement pour cette date.',
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        final event = dayEvents[index];
                        final color = event.color != null && event.color!.isNotEmpty
                            ? Color(int.tryParse(event.color!) ?? Colors.blue.value)
                            : _getCalendarColor(event.calendarId, calendars);

                        final startStr = event.allDay ? 'Toute la journée' : DateFormat('HH:mm').format(event.startDate);

                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(startStr),
                          onTap: () {
                            Navigator.pop(context); // Close bottom sheet
                            _showEventDetailsDialog(event, calendars);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectMonthYear(BuildContext context, DateTime currentDate) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _CustomDatePickerDialog(initialDate: currentDate),
        );
      },
    );
    if (picked != null) {
      ref.read(currentCalendarDateProvider.notifier).state = DateTime(picked.year, picked.month, 1);
    }
  }

  Widget _buildHorizontalAgendasSelector(List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    final selectedCalendarIds = ref.watch(selectedCalendarIdsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.black : theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: calendars.map((cal) {
                  final isSelected = selectedCalendarIds.contains(cal.id);
                  Color calendarColor = Colors.grey;
                  try {
                    final cleanHex = cal.color.replaceAll('#', '');
                    calendarColor = Color(int.parse('FF$cleanHex', radix: 16));
                  } catch (_) {}

                  final coverBase64 = _getCalendarCover(cal);
                  final lowerName = cal.name.toLowerCase();

                  // Fallback decorative icon
                  IconData iconData = Icons.calendar_today_rounded;
                  if (lowerName.contains('test')) {
                    iconData = Icons.favorite_rounded;
                  } else if (lowerName.contains('hyhyyy')) {
                    iconData = Icons.lock_rounded;
                  }

                  final chipBgColor = isSelected
                      ? (isDark ? const Color(0xFF4A4A4A) : const Color(0xFF333333))
                      : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBEBEB));
                  final textColor = isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[300] : const Color(0xFF333333));

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ref.read(selectedCalendarIdsProvider.notifier).toggleCalendar(cal.id, !isSelected);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: calendarColor,
                                borderRadius: BorderRadius.circular(6),
                                image: coverBase64.isNotEmpty && coverBase64 != 'default'
                                    ? DecorationImage(
                                        image: MemoryImage(base64Decode(coverBase64)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (coverBase64.isEmpty || coverBase64 == 'default'
                                      ? Center(
                                          child: Icon(
                                            iconData,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cal.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Week Grid View
  Widget _buildWeekView(BuildContext context, List<TimetreeEvent> events, List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    final focusedDate = ref.watch(currentCalendarDateProvider);
    final weekday = focusedDate.weekday;
    final weekStart = focusedDate.subtract(Duration(days: weekday - 1));

    final hours = List.generate(12, (index) => 8 + index); // 08:00 to 19:00

    return Column(
      children: [
        // Headers row: 7 days of selected week
        Container(
          color: theme.colorScheme.surfaceContainer,
          child: Row(
            children: [
              const SizedBox(width: 60), // Space for hours column
              ...List.generate(7, (idx) {
                final day = weekStart.add(Duration(days: idx));
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isToday
                        ? BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2)),
                          )
                        : null,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE', 'fr_FR').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.primary : Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(day),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Hourly grid
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hours label column
                Column(
                  children: hours.map((hour) {
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Days grids columns
                Expanded(
                  child: Row(
                    children: List.generate(7, (dayIdx) {
                      final dayDate = weekStart.add(Duration(days: dayIdx));
                      return Expanded(
                        child: Column(
                          children: hours.map((hour) {
                            final cellDateStart = DateTime(dayDate.year, dayDate.month, dayDate.day, hour, 0);
                            final cellDateEnd = DateTime(dayDate.year, dayDate.month, dayDate.day, hour, 59, 59);

                            final cellEvents = events.where((e) {
                              return e.startDate.isBefore(cellDateEnd) && e.endDate.isAfter(cellDateStart);
                            }).toList();

                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: cellEvents.isEmpty
                                  ? const SizedBox.shrink()
                                  : ListView(
                                      padding: EdgeInsets.zero,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: cellEvents.map((event) {
                                        final color = event.color != null && event.color!.isNotEmpty
                                            ? Color(int.tryParse(event.color!) ?? Colors.blue.value)
                                            : _getCalendarColor(event.calendarId, calendars);

                                        final unreadCounts = ref.watch(timetreeChatUnreadCountsProvider);
                                        final unreadCount = unreadCounts[event.id.toString()] ?? 0;

                                        final chip = Container(
                                          margin: const EdgeInsets.all(2),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      event.title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (unreadCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Text(
                                                        '$unreadCount',
                                                        style: const TextStyle(fontSize: 6, color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (event.participants.isNotEmpty)
                                                Row(
                                                  children: event.participants.take(3).map((p) {
                                                    final initials = p.fullName.isNotEmpty
                                                        ? p.fullName.substring(0, 1).toUpperCase()
                                                        : '?';
                                                    return Container(
                                                      margin: const EdgeInsets.only(right: 2, top: 1),
                                                      width: 10,
                                                      height: 10,
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white24,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          initials,
                                                          style: const TextStyle(fontSize: 6, color: Colors.white),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        );

                                        return InkWell(
                                          onTap: () => _showEventDetailsDialog(event, calendars),
                                          child: chip,
                                        );
                                      }).toList(),
                                    ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Day View Timeline
  Widget _buildDayView(BuildContext context, List<TimetreeEvent> events, List<TimetreeCalendar> calendars) {
    final theme = Theme.of(context);
    final focusedDate = ref.watch(currentCalendarDateProvider);
    final hours = List.generate(12, (index) => 8 + index); // 08:00 to 19:00

    return Column(
      children: [
        Container(
          color: theme.colorScheme.surfaceContainer,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              DateFormat('EEEE dd MMMM', 'fr_FR').format(focusedDate).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hours label column
                Column(
                  children: hours.map((hour) {
                    return SizedBox(
                      width: 60,
                      height: 70,
                      child: Center(
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Hourly slots for the day
                Expanded(
                  child: Column(
                    children: hours.map((hour) {
                      final cellStart = DateTime(focusedDate.year, focusedDate.month, focusedDate.day, hour, 0);
                      final cellEnd = DateTime(focusedDate.year, focusedDate.month, focusedDate.day, hour, 59, 59);

                      final hourEvents = events.where((e) {
                        return e.startDate.isBefore(cellEnd) && e.endDate.isAfter(cellStart);
                      }).toList();

                      return Container(
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: hourEvents.isEmpty
                            ? const SizedBox.shrink()
                            : Row(
                                children: hourEvents.map((event) {
                                  final color = event.color != null && event.color!.isNotEmpty
                                      ? Color(int.tryParse(event.color!) ?? Colors.blue.value)
                                      : _getCalendarColor(event.calendarId, calendars);

                                  final unreadCounts = ref.watch(timetreeChatUnreadCountsProvider);
                                  final unreadCount = unreadCounts[event.id.toString()] ?? 0;

                                  final card = Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                event.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (event.description != null && event.description!.isNotEmpty)
                                                Text(
                                                  event.description!,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                            child: Text(
                                              '$unreadCount',
                                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        if (event.participants.isNotEmpty)
                                          Row(
                                            children: event.participants.take(3).map((p) {
                                              final initials = p.fullName.isNotEmpty
                                                  ? p.fullName.substring(0, 1).toUpperCase()
                                                  : '?';
                                              return Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  );

                                  return Expanded(
                                    child: InkWell(
                                      onTap: () => _showEventDetailsDialog(event, calendars),
                                      child: card,
                                    ),
                                  );
                                }).toList(),
                              ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEventDetailsDialog(TimetreeEvent event, List<TimetreeCalendar> calendars) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TimetreeEventDetailsDialog(
          event: event,
          onRefresh: () {
            ref.read(timetreeEventsProvider.notifier).loadEvents();
          },
          onEditClicked: () {
            _showEventDialog(event, calendars);
          },
        );
      },
    );
  }

  // Create / Edit Event dialog integrating Custom Fields
  void _showEventDialog(TimetreeEvent? event, List<TimetreeCalendar> calendars, {DateTime? initialDate}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _EventFormDialog(
          event: event,
          calendars: calendars,
          initialDate: initialDate,
          onSuccess: () {
            ref.read(timetreeEventsProvider.notifier).loadEvents();
          },
        );
      },
    );
  }

  Future<void> _showExportBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final selectedCalendarIds = ref.read(selectedCalendarIdsProvider);
    
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exporter les événements',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un format d\'exportation pour télécharger la liste des événements de vos calendriers sélectionnés (${selectedCalendarIds.length}).',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildExportTile(ctx, 'Excel (XLSX)', Icons.grid_on_rounded, Colors.green, 'excel', 'events.xlsx'),
              _buildExportTile(ctx, 'PDF Document', Icons.picture_as_pdf_rounded, Colors.red, 'pdf', 'events.pdf'),
              _buildExportTile(ctx, 'CSV Tableur', Icons.table_chart_rounded, Colors.blue, 'csv', 'events.csv'),
              _buildExportTile(ctx, 'iCalendar (ICS)', Icons.calendar_today_rounded, Colors.indigo, 'ics', 'events.ics'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String format,
    String filename,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () async {
        Navigator.pop(context); // Close bottom sheet
        
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text('Génération du fichier $title en cours...'),
              ],
            ),
            duration: const Duration(days: 1), // Keep visible during operation
          ),
        );

        try {
          final selectedCalendarIds = ref.read(selectedCalendarIdsProvider).toList();
          final bytes = await ref.read(timetreeEventsRepositoryProvider).exportEvents(
            format,
            calendarIds: selectedCalendarIds.map((e) => e.toString()).toList(),
          );

          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(this.context).clearSnackBars();
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Téléchargé avec succès !\nSauvegardé dans: ${file.path}'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(this.context).clearSnackBars();
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'exportation : $e'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }
}

class _EventFormDialog extends ConsumerStatefulWidget {
  final TimetreeEvent? event;
  final List<TimetreeCalendar> calendars;
  final VoidCallback onSuccess;
  final DateTime? initialDate;

  const _EventFormDialog({
    this.event,
    required this.calendars,
    required this.onSuccess,
    this.initialDate,
  });

  @override
  ConsumerState<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customFieldsFormKey = GlobalKey<FormState>();

  late String _title;
  late String _nomEvent;
  late bool _titleModifiedDirectly;
  String? _description;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _allDay;
  late String _recurrenceRule;
  DateTime? _recurrenceEndDate;
  Color _selectedColor = Colors.blue;

  String? _selectedCalendarId;
  List<TimetreeMember> _selectedParticipants = [];

  // Hardening Sprint Fields
  late bool _locked;
  late bool _isPrivate;
  late String _status;
  late String _priority;
  List<TimetreeTag> _selectedTags = [];
  List<Map<String, dynamic>> _selectedDependencies = [];
  bool _rem15m = false;
  bool _rem1h = false;
  bool _rem1d = false;
  List<DateTime> _customReminders = [];
  final _tagInputController = TextEditingController();

  // Dynamic Custom Fields State
  List<TimetreeCustomField> _customFields = [];
  Map<String, String> _customFieldValues = {};
  Map<String, bool> _customFieldEmojiValues = {};
  bool _loadingFields = false;

  @override
  void dispose() {
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final ev = widget.event;

    _title = ev?.title ?? '';
    _nomEvent = ev?.nomEvent ?? ev?.title ?? '';
    _titleModifiedDirectly = ev?.titleModifiedDirectly ?? false;
    _description = ev?.description;
    _startDate = ev?.startDate ?? widget.initialDate ?? DateTime.now();
    _endDate = ev?.endDate ?? (widget.initialDate != null 
        ? widget.initialDate!.add(const Duration(hours: 1)) 
        : DateTime.now().add(const Duration(hours: 1)));
    _allDay = ev?.allDay ?? false;
    _recurrenceRule = ev?.recurrenceRule ?? 'NONE';
    _recurrenceEndDate = ev?.recurrenceEndDate;

    _locked = ev?.locked ?? false;
    _isPrivate = ev?.isPrivate ?? false;
    _status = ev?.status ?? 'PLANNED';
    _priority = ev?.priority ?? 'NORMAL';
    _selectedTags = ev?.tags != null ? List<TimetreeTag>.from(ev!.tags) : [];
    _selectedDependencies = ev?.dependencies != null ? List<Map<String, dynamic>>.from(ev!.dependencies) : [];

    if (ev != null) {
      _selectedCalendarId = ev.calendarId;
      _selectedParticipants = List<TimetreeMember>.from(ev.participants);
      if (ev.color != null && ev.color!.isNotEmpty) {
        _selectedColor = Color(int.tryParse(ev.color!) ?? Colors.blue.value);
      }
      
      // Parse reminders
      for (final rem in ev.reminders) {
        final diff = ev.startDate.difference(rem);
        if (diff.inMinutes == 15) {
          _rem15m = true;
        } else if (diff.inHours == 1) {
          _rem1h = true;
        } else if (diff.inDays == 1) {
          _rem1d = true;
        } else {
          _customReminders.add(rem);
        }
      }

      _loadCustomFieldValuesAndFields();
    } else {
      // Default to first calendar if available
      if (widget.calendars.isNotEmpty) {
        _selectedCalendarId = widget.calendars.first.id;
        _loadCustomFields();
      }
    }
  }

  // Load field definitions
  Future<void> _loadCustomFields() async {
    if (_selectedCalendarId == null) return;
    setState(() {
      _loadingFields = true;
    });

    try {
      final fields = await ref.read(timetreeCustomFieldsRepositoryProvider).getEventFields(
            calendarId: _selectedCalendarId,
          );
      setState(() {
        _customFields = fields;
        _loadingFields = false;
      });
    } catch (_) {
      setState(() {
        _loadingFields = false;
      });
    }
  }

  // Load custom field values & definitions for edit mode
  Future<void> _loadCustomFieldValuesAndFields() async {
    final ev = widget.event;
    if (ev == null) return;

    setState(() {
      _loadingFields = true;
    });

    try {
      final baseEventId = ev.id.split('_rec_').first;

      // 1. Fetch Field definitions
      final fields = await ref.read(timetreeCustomFieldsRepositoryProvider).getEventFields(
            calendarId: ev.calendarId,
            eventId: baseEventId,
          );

      // 2. Fetch Saved field values
      final values = await ref.read(timetreeCustomFieldsRepositoryProvider).getCustomFieldValues(
            'EVENT',
            baseEventId,
          );

      final Map<String, String> valuesMap = {};
      final Map<String, bool> emojiMap = {};
      for (final val in values) {
        if (val.value != null) {
          valuesMap[val.field.id] = val.value!;
        }
        emojiMap[val.field.id] = val.showEmojiInTitle;
      }

      setState(() {
        _customFields = fields;
        _customFieldValues = valuesMap;
        _customFieldEmojiValues = emojiMap;
        _loadingFields = false;
      });
    } catch (e) {
      AppLogger.e('EventFormDialogState', 'Error loading custom fields', e);
      setState(() {
        _loadingFields = false;
      });
    }
  }

  void _onCalendarChanged(String? calendarId) {
    setState(() {
      _selectedCalendarId = calendarId;
      _selectedParticipants = [];
      _customFields = [];
      _customFieldValues = {};
      _customFieldEmojiValues = {};
    });
    _loadCustomFields();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        setState(() {
          final full = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            _startDate = full;
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _endDate = full;
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    final isBaseFormValid = _formKey.currentState?.validate() ?? false;
    final isCustomFieldsValid = _customFields.isEmpty ||
        (_customFieldsFormKey.currentState?.validate() ?? false);

    if (!isBaseFormValid || !isCustomFieldsValid) return;

    _formKey.currentState?.save();

    // Compile reminders list
    final List<DateTime> compiledReminders = [];
    if (_rem15m) {
      compiledReminders.add(_startDate.subtract(const Duration(minutes: 15)));
    }
    if (_rem1h) {
      compiledReminders.add(_startDate.subtract(const Duration(hours: 1)));
    }
    if (_rem1d) {
      compiledReminders.add(_startDate.subtract(const Duration(days: 1)));
    }
    compiledReminders.addAll(_customReminders);

    final ev = TimetreeEvent(
      id: widget.event?.id ?? '',
      title: _title,
      description: _description,
      startDate: _startDate,
      endDate: _endDate,
      allDay: _allDay,
      color: _selectedColor.value.toString(),
      calendarId: _selectedCalendarId!,
      groupId: null,
      recurrenceRule: _recurrenceRule,
      recurrenceEndDate: _recurrenceEndDate,
      participants: _selectedParticipants,
      locked: _locked,
      isPrivate: _isPrivate,
      status: _status,
      priority: _priority,
      tags: _selectedTags,
      dependencies: _selectedDependencies,
      reminders: compiledReminders,
      nomEvent: _nomEvent,
      titleModifiedDirectly: _titleModifiedDirectly,
    );

    try {
      final Map<String, dynamic> payload = {};
      for (final entry in _customFieldValues.entries) {
        payload[entry.key] = {
          'value': entry.value,
          'showEmojiInTitle': _customFieldEmojiValues[entry.key] ?? false,
        };
      }

      if (widget.event == null) {
        // Create event
        await ref.read(timetreeEventsProvider.notifier).createEvent(ev);
        
        // Find the newly created event (latest in list or we find the one matching properties)
        final eventsList = ref.read(timetreeEventsProvider).value ?? [];
        final created = eventsList.firstWhere(
          (e) => e.title == _title && e.startDate == _startDate && e.calendarId == _selectedCalendarId,
          orElse: () => ev,
        );

        if (created.id.isNotEmpty && payload.isNotEmpty) {
          final baseCreatedId = created.id.split('_rec_').first;
          await ref.read(timetreeCustomFieldsRepositoryProvider).saveCustomFieldValues(
                'EVENT',
                baseCreatedId,
                payload,
              );
        }
      } else {
        // Update event
        final baseEventId = widget.event!.id.split('_rec_').first;
        await ref.read(timetreeEventsProvider.notifier).updateEvent(baseEventId, ev);
        
        if (payload.isNotEmpty) {
          await ref.read(timetreeCustomFieldsRepositoryProvider).saveCustomFieldValues(
                'EVENT',
                baseEventId,
                payload,
              );
        }
      }

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistré avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role.toUpperCase() ?? 'MEMBER';

    final selectedCalendar = widget.calendars.firstWhere(
      (c) => c.id == _selectedCalendarId,
      orElse: () => widget.calendars.isNotEmpty ? widget.calendars.first : const TimetreeCalendar(id: '', name: '', description: '', color: '#2196F3', members: []),
    );
    final calendarMembers = selectedCalendar.members;
    final memberInCal = calendarMembers.firstWhere(
      (m) => m.username.toLowerCase() == user?.username.toLowerCase(),
      orElse: () => const TimetreeMember(id: '', username: '', fullName: '', email: '', role: ''),
    );
    final isChefOrAdmin = role == 'ADMIN' ||
        role == 'ADMINISTRATEUR' ||
        role == 'CHEF' ||
        memberInCal.role.toUpperCase() == 'CHEF' ||
        memberInCal.role.toUpperCase() == 'ADMIN' ||
        memberInCal.role.toUpperCase() == 'ADMINISTRATEUR';

    Color dialogThemeColor = Colors.blue;
    try {
      final cleanHex = selectedCalendar.color.replaceAll('#', '');
      dialogThemeColor = Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {}

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: dialogThemeColor,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: AlertDialog(
        title: Text(widget.event == null ? 'Nouvel Événement' : 'Modifier l\'Événement'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _nomEvent,
                    decoration: const InputDecoration(labelText: "Nom de l'événement", border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Nom de l'événement requis" : null,
                    onSaved: (val) => _nomEvent = val ?? '',
                    onChanged: (val) {
                      setState(() {
                        _nomEvent = val;
                        if (!_titleModifiedDirectly) {
                          _title = val;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isChefOrAdmin) ...[
                    TextFormField(
                      initialValue: _title,
                      key: ValueKey('title_field_$_titleModifiedDirectly'),
                      decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()),
                      enabled: _titleModifiedDirectly,
                      validator: (val) => (_titleModifiedDirectly && (val == null || val.trim().isEmpty)) ? 'Titre requis' : null,
                      onSaved: (val) => _title = val ?? '',
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Modifier le titre directement (outrepasser les émojis)'),
                      value: _titleModifiedDirectly,
                      onChanged: (val) {
                        setState(() {
                          _titleModifiedDirectly = val ?? false;
                          if (!_titleModifiedDirectly) {
                            _title = _nomEvent;
                          }
                        });
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      initialValue: _title.isNotEmpty ? _title : "Généré automatiquement",
                      decoration: const InputDecoration(labelText: 'Titre (Lecture seule)', border: OutlineInputBorder()),
                      enabled: false,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    onSaved: (val) => _description = val,
                  ),
                  const SizedBox(height: 12),
  
                  // Calendar select (Only Calendar, no Group)
                  DropdownButtonFormField<String>(
                    value: _selectedCalendarId,
                    decoration: const InputDecoration(labelText: 'Agenda', border: OutlineInputBorder()),
                    items: widget.calendars.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: widget.event != null ? null : _onCalendarChanged,
                    validator: (val) => val == null ? 'Agenda requis' : null,
                  ),
                const SizedBox(height: 12),

                // Date Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Début', style: TextStyle(fontSize: 12)),
                        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(_startDate)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _pickDateTime(true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fin', style: TextStyle(fontSize: 12)),
                        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(_endDate)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _pickDateTime(false),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Toute la journée', style: TextStyle(fontSize: 14)),
                  value: _allDay,
                  onChanged: (val) => setState(() => _allDay = val),
                ),
                const SizedBox(height: 12),

                // Recurrence options
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _recurrenceRule,
                        decoration: const InputDecoration(labelText: 'Répétition', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'NONE', child: Text('Aucune')),
                          DropdownMenuItem(value: 'DAILY', child: Text('Tous les jours')),
                          DropdownMenuItem(value: 'WEEKLY', child: Text('Toutes les semaines')),
                          DropdownMenuItem(value: 'MONTHLY', child: Text('Tous les mois')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _recurrenceRule = val;
                              if (val == 'NONE') {
                                _recurrenceEndDate = null;
                              } else {
                                _recurrenceEndDate = _startDate.add(const Duration(days: 30));
                              }
                            });
                          }
                        },
                      ),
                    ),
                    if (_recurrenceRule != 'NONE') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fin de récurrence', style: TextStyle(fontSize: 12)),
                          subtitle: Text(_recurrenceEndDate != null
                              ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_recurrenceEndDate!)
                              : 'Indéfinie'),
                          trailing: const Icon(Icons.date_range),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _recurrenceEndDate ?? _startDate,
                              firstDate: _startDate,
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _recurrenceEndDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Color picker
                const Text('Couleur de l\'événement', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue,
                    Colors.green,
                    Colors.red,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                  ].map((color) {
                    final isSelected = _selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: isSelected ? [const BoxShadow(blurRadius: 4, color: Colors.black26)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Workflow status and priority Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'DRAFT', child: Text('Brouillon')),
                          DropdownMenuItem(value: 'PLANNED', child: Text('Planifié')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('En cours')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('Terminé')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('Annulé')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'Priorité', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                          DropdownMenuItem(value: 'NORMAL', child: Text('Normale')),
                          DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                          DropdownMenuItem(value: 'CRITICAL', child: Text('Critique')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _priority = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Locked and Private switches
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Événement Privé', style: TextStyle(fontSize: 14)),
                        value: _isPrivate,
                        onChanged: (val) => setState(() => _isPrivate = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (role == 'ADMIN' || role == 'ADMINISTRATEUR' || role == 'CHEF') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Verrouiller', style: TextStyle(fontSize: 14)),
                          value: _locked,
                          onChanged: (val) => setState(() => _locked = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Reusable Tags Picker
                const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_selectedTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
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
                      return Chip(
                        label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                        backgroundColor: tagColor.withValues(alpha: 0.15),
                        side: BorderSide(color: tagColor.withValues(alpha: 0.5)),
                        onDeleted: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagInputController,
                        decoration: const InputDecoration(
                          labelText: 'Ajouter un tag',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                      onPressed: () {
                        final text = _tagInputController.text.trim();
                        if (text.isNotEmpty) {
                          setState(() {
                            if (!_selectedTags.any((t) => t.name.toLowerCase() == text.toLowerCase())) {
                              _selectedTags.add(
                                TimetreeTag(
                                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                  name: text,
                                  color: _selectedColor.value.toString(),
                                ),
                              );
                            }
                            _tagInputController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Event dependencies picker
                const Text('Dépendances d\'événements', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un événement parent',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: (ref.read(timetreeEventsProvider).value ?? [])
                      .where((e) => e.id != widget.event?.id)
                      .map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(e.title),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final allEvents = ref.read(timetreeEventsProvider).value ?? [];
                      final depEvent = allEvents.firstWhere((e) => e.id == val);
                      if (!_selectedDependencies.any((d) => d['id'].toString() == val)) {
                        setState(() {
                          _selectedDependencies.add({
                            'id': depEvent.id,
                            'title': depEvent.title,
                            'status': depEvent.status,
                          });
                        });
                      }
                    }
                  },
                ),
                if (_selectedDependencies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedDependencies.map((dep) {
                      return Chip(
                        label: Text('Dépend de: ${dep['title']}', style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        onDeleted: () {
                          setState(() {
                            _selectedDependencies.removeWhere((d) => d['id'].toString() == dep['id'].toString());
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Reminders checklist
                const Text('Rappels automatiques', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: const Text('15 min avant', style: TextStyle(fontSize: 13)),
                            value: _rem15m,
                            onChanged: (val) => setState(() => _rem15m = val ?? false),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text('1 heure avant', style: TextStyle(fontSize: 13)),
                            value: _rem1h,
                            onChanged: (val) => setState(() => _rem1h = val ?? false),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text('1 jour avant', style: TextStyle(fontSize: 13)),
                            value: _rem1d,
                            onChanged: (val) => setState(() => _rem1d = val ?? false),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.add_alarm_rounded, size: 18),
                            label: const Text('Ajouter un rappel', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                if (!context.mounted) return;
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    _customReminders.add(DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    ));
                                  });
                                }
                              }
                            },
                          ),
                          if (_customReminders.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _customReminders.map((rem) {
                                final rStr = DateFormat('dd/MM HH:mm').format(rem);
                                return Chip(
                                  label: Text(rStr, style: const TextStyle(fontSize: 10)),
                                  onDeleted: () => setState(() => _customReminders.remove(rem)),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calendar Participants selector
                const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (calendarMembers.isEmpty)
                  const Text('Aucun membre dans cet agenda pour le moment.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: calendarMembers.map((member) {
                      final isSelected = _selectedParticipants.any((p) => p.id == member.id);
                      final initials = member.fullName.isNotEmpty
                          ? member.fullName.substring(0, 1).toUpperCase()
                          : '?';

                      return FilterChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? Colors.white30 : Colors.blueGrey,
                          child: Text(initials, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        label: Text(member.fullName),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedParticipants.add(member);
                            } else {
                              _selectedParticipants.removeWhere((p) => p.id == member.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // Dynamic Custom Fields header & section
                const Divider(),
                const Text('Champs Personnalisés', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_loadingFields)
                  const Center(child: CircularProgressIndicator())
                else if (_customFields.isEmpty)
                  const Text('Aucun champ personnalisé défini pour cet agenda.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  DynamicEventFormRenderer(
                    fields: _customFields,
                    values: _customFieldValues,
                    showEmojiInTitleValues: _customFieldEmojiValues,
                    formKey: _customFieldsFormKey,
                    onValuesChanged: (vals, emojis) {
                      _customFieldValues = vals;
                      _customFieldEmojiValues = emojis;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.event != null)
          TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer l\'événement ?'),
                  content: const Text('Cette action supprimera également toutes les occurrences de cet événement récurrent.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Close warning dialog
                        try {
                          await ref.read(timetreeEventsProvider.notifier).deleteEvent(widget.event!.id);
                          widget.onSuccess();
                          if (context.mounted) Navigator.pop(context); // Close edit dialog
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saveEvent,
          child: const Text('Enregistrer'),
        ),
      ],
    ),
    );
  }
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _CustomDatePickerDialog({Key? key, required this.initialDate}) : super(key: key);

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  int _selectedMonth = 1;
  int _selectedYear = 2026;
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _gridDays = [];

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  final List<String> _weekdays = ['DIM', 'LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;
    _selectedDate = widget.initialDate;
    _updateDays();
  }

  void _updateDays() {
    final days = <DateTime>[];
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final leadingOffset = firstDay.weekday % 7;
    final prevMonth = DateTime(_selectedYear, _selectedMonth - 1, 1);
    final daysInPrevMonth = DateTime(_selectedYear, _selectedMonth, 0).day;
    
    for (int i = leadingOffset - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
    }
    
    final daysInCurrentMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    for (int i = 1; i <= daysInCurrentMonth; i++) {
      days.add(DateTime(_selectedYear, _selectedMonth, i));
    }
    
    final trailingCount = 42 - days.length;
    final nextMonth = DateTime(_selectedYear, _selectedMonth + 1, 1);
    for (int i = 1; i <= trailingCount; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }
    
    setState(() {
      _gridDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTextColor = isDark ? Colors.white : Colors.black87;
    final years = List<int>.generate(21, (i) => 2020 + i);

    return SizedBox(
      width: 320,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main calendar card
          Container(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 60, // extra padding for the overlapping footer
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month / Year Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedMonth,
                            isExpanded: true,
                            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(
                                  _months[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: activeTextColor,
                                  ),
                                ),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMonth = val;
                                  _updateDays();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            isExpanded: true,
                            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            items: years.map((y) {
                              return DropdownMenuItem<int>(
                                value: y,
                                child: Text(
                                  '$y',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: activeTextColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedYear = val;
                                  _updateDays();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Weekday Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdays.map((day) {
                    return SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Days Grid
                Column(
                  children: List.generate(6, (rowIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (colIndex) {
                          final index = rowIndex * 7 + colIndex;
                          if (index >= _gridDays.length) {
                            return const SizedBox(width: 32, height: 32);
                          }
                          
                          final date = _gridDays[index];
                          final isCurrentMonth = date.month == _selectedMonth && date.year == _selectedYear;
                          final isSelected = date.day == _selectedDate.day &&
                              date.month == _selectedDate.month &&
                              date.year == _selectedDate.year;
                          
                          Color textColor;
                          if (isSelected) {
                            textColor = Colors.white;
                          } else if (isCurrentMonth) {
                            textColor = activeTextColor;
                          } else {
                            textColor = isDark ? Colors.grey[750]! : Colors.grey[350]!;
                          }
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                                if (date.month != _selectedMonth || date.year != _selectedYear) {
                                  _selectedMonth = date.month;
                                  _selectedYear = date.year;
                                  _updateDays();
                                }
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blueAccent : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Overlapping bottom footer card
          Positioned(
            bottom: -20,
            left: 10,
            right: 10,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Formatted Date
                  Expanded(
                    child: Text(
                      (() {
                        final raw = DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate);
                        if (raw.isEmpty) return '';
                        final parts = raw.split(' ');
                        if (parts.length == 3) {
                          final month = parts[1];
                          if (month.isNotEmpty) {
                            parts[1] = month[0].toUpperCase() + month.substring(1);
                          }
                          return parts.join(' ');
                        }
                        return raw;
                      })(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: activeTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Cancel / Confirm Actions
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
