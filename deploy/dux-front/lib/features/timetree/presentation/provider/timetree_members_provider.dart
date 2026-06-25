import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_members_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';

/// StateNotifier for managing the list of TimeTree Members.
class TimetreeMembersNotifier extends StateNotifier<AsyncValue<List<TimetreeMember>>> {
  final TimetreeMembersRepository _repository;

  TimetreeMembersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  /// Fetches the members list.
  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getMembers();
      // Sort alphabetically by full name
      list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new member.
  Future<void> createMember({
    required String username,
    required String fullName,
    required String email,
    required String role,
    List<String>? calendarIds,
  }) async {
    final currentList = state.value ?? [];
    try {
      final newMember = await _repository.createMember(
        username: username,
        fullName: fullName,
        email: email,
        role: role,
        calendarIds: calendarIds,
      );
      final updatedList = List<TimetreeMember>.from(currentList)..add(newMember);
      updatedList.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing member.
  Future<void> updateMember({
    required String id,
    required String username,
    required String fullName,
    required String email,
    required String role,
    bool? canCreateAgendas,
    bool? canAddMembers,
    String? profilePicture,
    List<String>? calendarIds,
  }) async {
    final currentList = state.value ?? [];
    try {
      final updatedMember = await _repository.updateMember(
        id: id,
        username: username,
        fullName: fullName,
        email: email,
        role: role,
        canCreateAgendas: canCreateAgendas,
        canAddMembers: canAddMembers,
        profilePicture: profilePicture,
        calendarIds: calendarIds,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedMember : item;
      }).toList();
      updatedList.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Deletes a member.
  Future<void> deleteMember(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deleteMember(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

/// Provider for [TimetreeMembersNotifier].
final timetreeMembersProvider =
    StateNotifierProvider.autoDispose<TimetreeMembersNotifier, AsyncValue<List<TimetreeMember>>>((ref) {
  final repo = ref.watch(timetreeMembersRepositoryProvider);
  return TimetreeMembersNotifier(repo);
});

/// Holds the search filter query for Members.
final timetreeMemberSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider that exposes a filtered list of members based on search query.
final filteredTimetreeMembersProvider = Provider.autoDispose<AsyncValue<List<TimetreeMember>>>((ref) {
  final membersAsync = ref.watch(timetreeMembersProvider);
  final searchQuery = ref.watch(timetreeMemberSearchQueryProvider).trim().toLowerCase();

  return membersAsync.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list
        .where((m) =>
            m.fullName.toLowerCase().contains(searchQuery) ||
            m.username.toLowerCase().contains(searchQuery) ||
            m.email.toLowerCase().contains(searchQuery) ||
            m.role.toLowerCase().contains(searchQuery))
        .toList();
  });
});
