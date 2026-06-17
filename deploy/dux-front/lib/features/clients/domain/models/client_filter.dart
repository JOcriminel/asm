class ClientFilter {
  final String searchTerm;
  final String typeTier;
  final DateTime? startDate;
  final DateTime? endDate;

  const ClientFilter({
    this.searchTerm = '',
    this.typeTier = '1',
    this.startDate,
    this.endDate,
  });

  ClientFilter copyWith({
    String? searchTerm,
    String? typeTier,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ClientFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      typeTier: typeTier ?? this.typeTier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
