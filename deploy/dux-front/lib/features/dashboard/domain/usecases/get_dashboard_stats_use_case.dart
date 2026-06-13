import '../../../commands/domain/models/command.dart';
import '../models/dashboard_stats.dart';

/// Use-case: derive dashboard KPI statistics from an already-fetched command list.
/// Extracted from [dashboard_screen.dart] build() method (Single Responsibility).
/// Pure computation — no side effects, no Flutter dependencies.
class GetDashboardStatsUseCase {
  const GetDashboardStatsUseCase();

  DashboardStats call(List<Command> commands) {
    if (commands.isEmpty) return const DashboardStats.empty();

    int delivered = 0;
    int validated = 0;
    int pending = 0;
    double totalAmountTTC = 0.0;

    for (final cmd in commands) {
      final s = cmd.status.toLowerCase();
      totalAmountTTC += cmd.amountTTC;

      if (s.contains('livr') || s.contains('clôtur') || s.contains('terminé')) {
        delivered++;
      } else if (s.contains('valid')) {
        validated++;
      } else {
        pending++;
      }
    }

    return DashboardStats(
      totalCommands: commands.length,
      delivered: delivered,
      validated: validated,
      pending: pending,
      totalAmountTTC: totalAmountTTC,
    );
  }
}
