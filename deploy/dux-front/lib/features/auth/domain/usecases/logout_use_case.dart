import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/storage_service.dart';

/// Use-case: clear all session data and sign the user out.
class LogoutUseCase {
  final AuthRepository _repository;
  final StorageService _storageService;

  const LogoutUseCase(this._repository, this._storageService);

  Future<void> call() async {
    await _repository.logout();
    await _storageService.delete('auth_token');
  }
}
