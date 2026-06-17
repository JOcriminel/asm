import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/features/commands/domain/models/command.dart';
import '../../domain/usecases/determine_timeline_status_use_case.dart';

class TimelineWidget extends StatelessWidget {
  final Command command;

  const TimelineWidget({
    super.key,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const determineStatus = DetermineTimelineStatusUseCase();
    final status = determineStatus(command);
    final timeline = command.timeline;

    final stages = [
      _StageData(
        title: 'Created',
        date: timeline.created,
        status: status.created,
      ),
      _StageData(
        title: 'Validated',
        date: timeline.validated,
        status: status.validated,
      ),
      _StageData(
        title: 'Delivered',
        date: timeline.delivered,
        status: status.delivered,
      ),
    ];

    return InfoCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l, horizontal: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stages.length, (index) {
          final stage = stages[index];
          final isCompleted = stage.status == TimelineStepStatus.completed;
          final isActive = stage.status == TimelineStepStatus.active;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Left connecting line
                    Expanded(
                      child: Divider(
                        color: index == 0
                            ? Colors.transparent
                            : (isCompleted || isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline),
                        thickness: 2.5,
                      ),
                    ),
                    // Icon / Indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : (isActive
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : (isActive
                                ? Icons.lens
                                : Icons.radio_button_unchecked),
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : (isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline),
                        size: isActive ? 22 : 24,
                      ),
                    ),
                    // Right connecting line
                    Expanded(
                      child: Divider(
                        color: index == stages.length - 1
                            ? Colors.transparent
                            : (stages[index + 1].status == TimelineStepStatus.completed
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline),
                        thickness: 2.5,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapS,
                Text(
                  stage.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isCompleted || isActive ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? theme.colorScheme.onSurface
                        : (isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary),
                  ),
                ),
                if (stage.date != null && (isCompleted || isActive)) ...[
                  AppSpacing.gapXs,
                  Text(
                    DateFormat('MMM dd, HH:mm').format(stage.date!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StageData {
  final String title;
  final DateTime? date;
  final TimelineStepStatus status;

  const _StageData({
    required this.title,
    this.date,
    required this.status,
  });
}
