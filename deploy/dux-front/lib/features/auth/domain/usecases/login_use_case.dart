import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/storage_service.dart';

/// Use-case: log in with credentials, optionally persist the session.
/// Single responsibility: orchestrate login + session persistence.
/// The controller no longer embeds this logic.
class LoginUseCase {
  final AuthRepository _repository;
  final StorageService _storageService;

  const LoginUseCase(this._repository, this._storageService);

  Future<User> call(String username, String password, {bool rememberMe = true}) async {
    final user = await _repository.login(username, password);
    await _storageService.write(
      'persist_session',
      rememberMe ? 'true' : 'false',
    );
    return user;
  }
}
