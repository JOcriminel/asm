import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Use-case: fetch the authenticated user's profile.
class GetProfileUseCase {
  final ProfileRepository _repository;

  const GetProfileUseCase(this._repository);

  Future<Profile> call(String login) => _repository.getProfile(login);
}
