import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_attachments_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_attachment.dart';

class TimetreeAttachmentsState {
  final List<TimetreeAttachment> attachments;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const TimetreeAttachmentsState({
    this.attachments = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  TimetreeAttachmentsState copyWith({
    List<TimetreeAttachment>? attachments,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) {
    return TimetreeAttachmentsState(
      attachments: attachments ?? this.attachments,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

class TimetreeAttachmentsNotifier extends StateNotifier<TimetreeAttachmentsState> {
  final TimetreeAttachmentsRepository _repository;
  final String _eventId;

  TimetreeAttachmentsNotifier(this._repository, this._eventId)
      : super(const TimetreeAttachmentsState()) {
    loadAttachments();
  }

  Future<void> loadAttachments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getAttachments(_eventId);
      state = state.copyWith(attachments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> uploadFile(String filePath, String fileName) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final newAttachment = await _repository.uploadAttachment(_eventId, filePath, fileName);
      state = state.copyWith(
        attachments: [...state.attachments, newAttachment],
        isUploading: false,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final currentList = state.attachments;
    try {
      await _repository.deleteAttachment(attachmentId);
      state = state.copyWith(
        attachments: currentList.where((a) => a.id != attachmentId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<int>> downloadAttachment(String attachmentId) async {
    try {
      return await _repository.downloadAttachment(attachmentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final timetreeAttachmentsProvider = StateNotifierProvider.family
    .autoDispose<TimetreeAttachmentsNotifier, TimetreeAttachmentsState, String>((ref, eventId) {
  final repository = ref.watch(timetreeAttachmentsRepositoryProvider);
  return TimetreeAttachmentsNotifier(repository, eventId);
});
