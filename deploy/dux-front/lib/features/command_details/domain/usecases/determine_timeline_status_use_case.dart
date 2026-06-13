import '../../../commands/domain/models/command.dart';

/// Value object — the completion stage of each timeline step.
enum TimelineStepStatus { completed, active, pending }

/// Result of timeline status computation.
class TimelineStatus {
  final TimelineStepStatus created;
  final TimelineStepStatus validated;
  final TimelineStepStatus delivered;

  const TimelineStatus({
    required this.created,
    required this.validated,
    required this.delivered,
  });
}

/// Pure domain use-case: compute which timeline steps are complete/active/pending.
///
/// Extracted from [command_details_screen.dart] — the screen now has zero
/// business logic (Single Responsibility).
///
/// Rules:
///   • A step is COMPLETED  iff it has a date AND the document status word
///     confirms it (e.g., "Livré" for delivered).
///   • The first incomplete step after any completed step is ACTIVE.
///   • All remaining steps are PENDING.
class DetermineTimelineStatusUseCase {
  const DetermineTimelineStatusUseCase();

  TimelineStatus call(Command command) {
    final status = command.status.toLowerCase();
    final tl = command.timeline;

    final createdDone = tl.created != null;
    final validatedDone = tl.validated != null &&
        (status.contains('valid') ||
            status.contains('livr') ||
            status.contains('terminé') ||
            status.contains('clôtur'));
    final deliveredDone = tl.delivered != null &&
        (status.contains('livr') ||
            status.contains('terminé') ||
            status.contains('clôtur'));

    return TimelineStatus(
      created: createdDone ? TimelineStepStatus.completed : TimelineStepStatus.active,
      validated: validatedDone
          ? TimelineStepStatus.completed
          : (createdDone ? TimelineStepStatus.active : TimelineStepStatus.pending),
      delivered: deliveredDone
          ? TimelineStepStatus.completed
          : (validatedDone ? TimelineStepStatus.active : TimelineStepStatus.pending),
    );
  }
}
