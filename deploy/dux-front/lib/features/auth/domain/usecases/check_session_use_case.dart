import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/storage_service.dart';

/// Use-case: restore an existing session from persisted token.
/// Returns null if no valid session exists.
class CheckSessionUseCase {
  final AuthRepository _repository;
  final StorageService _storageService;

  const CheckSessionUseCase(this._repository, this._storageService);

  Future<User?> call() async {
    final persist = await _storageService.read('persist_session');
    if (persist == 'false') {
      await _storageService.delete('auth_token');
      await _storageService.delete('persist_session');
      return null;
    }

    final token = await _storageService.read('auth_token');
    if (token == null || token.isEmpty) return null;

    return _repository.getCurrentUser(token);
  }
}
