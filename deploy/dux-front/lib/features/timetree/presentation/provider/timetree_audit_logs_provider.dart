import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_audit_logs_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

class TimetreeAuditLogsState {
  final List<TimetreeAuditLog> logs;
  final bool isLoading;
  final String? error;

  final String? username;
  final String? action;
  final String? entityType;
  final String? entityId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? search;

  const TimetreeAuditLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.username,
    this.action,
    this.entityType,
    this.entityId,
    this.startDate,
    this.endDate,
    this.search,
  });

  TimetreeAuditLogsState copyWith({
    List<TimetreeAuditLog>? logs,
    bool? isLoading,
    String? error,
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    bool clearUsername = false,
    bool clearAction = false,
    bool clearEntityType = false,
    bool clearEntityId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearch = false,
  }) {
    return TimetreeAuditLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      username: clearUsername ? null : (username ?? this.username),
      action: clearAction ? null : (action ?? this.action),
      entityType: clearEntityType ? null : (entityType ?? this.entityType),
      entityId: clearEntityId ? null : (entityId ?? this.entityId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class TimetreeAuditLogsNotifier extends StateNotifier<TimetreeAuditLogsState> {
  final TimetreeAuditLogsRepository _repository;

  TimetreeAuditLogsNotifier(this._repository) : super(const TimetreeAuditLogsState()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getAuditLogs(
        username: state.username,
        action: state.action,
        entityType: state.entityType,
        entityId: state.entityId,
        startDate: state.startDate?.toUtc().toIso8601String(),
        endDate: state.endDate?.toUtc().toIso8601String(),
        search: state.search,
      );
      state = state.copyWith(logs: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateFilters({
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    bool clearUsername = false,
    bool clearAction = false,
    bool clearEntityType = false,
    bool clearEntityId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearch = false,
  }) {
    state = state.copyWith(
      username: username,
      action: action,
      entityType: entityType,
      entityId: entityId,
      startDate: startDate,
      endDate: endDate,
      search: search,
      clearUsername: clearUsername,
      clearAction: clearAction,
      clearEntityType: clearEntityType,
      clearEntityId: clearEntityId,
      clearStartDate: clearStartDate,
      clearEndDate: clearEndDate,
      clearSearch: clearSearch,
    );
    loadLogs();
  }

  Future<List<int>> downloadCsv() async {
    return await _repository.downloadAuditLogsCsv(
      username: state.username,
      action: state.action,
      entityType: state.entityType,
      entityId: state.entityId,
      startDate: state.startDate?.toUtc().toIso8601String(),
      endDate: state.endDate?.toUtc().toIso8601String(),
      search: state.search,
    );
  }
}

final timetreeAuditLogsProvider = StateNotifierProvider.autoDispose<TimetreeAuditLogsNotifier, TimetreeAuditLogsState>((ref) {
  final repository = ref.watch(timetreeAuditLogsRepositoryProvider);
  return TimetreeAuditLogsNotifier(repository);
});
