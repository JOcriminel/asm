import '../../domain/models/profile.dart';

/// Domain port for user profile retrieval.
abstract class ProfileRepository {
  Future<Profile> getProfile(String login);
}
