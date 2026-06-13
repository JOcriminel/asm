import '../../domain/models/user.dart';

/// Domain port for authentication.
/// The abstract class lives in the domain layer; implementations live in data/.
/// This enforces Dependency Inversion — controllers depend on this abstraction,
/// never on a concrete HTTP class.
abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> getCurrentUser(String token);
  Future<void> logout();
}
