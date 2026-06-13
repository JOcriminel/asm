/// Immutable value object for dashboard KPI statistics.
class DashboardStats {
  final int totalCommands;
  final int delivered;
  final int validated;
  final int pending;
  final double totalAmountTTC;

  const DashboardStats({
    required this.totalCommands,
    required this.delivered,
    required this.validated,
    required this.pending,
    required this.totalAmountTTC,
  });

  const DashboardStats.empty()
      : totalCommands = 0,
        delivered = 0,
        validated = 0,
        pending = 0,
        totalAmountTTC = 0.0;
}
