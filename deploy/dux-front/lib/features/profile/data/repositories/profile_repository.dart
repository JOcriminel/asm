import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../services/profile_api_service.dart';
import '../models/profile_dto.dart';
import '../mappers/profile_mapper.dart';
import '../../../../core/services/storage_service.dart';

/// Concrete implementation of [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService _apiService;
  final StorageService _storageService;

  const ProfileRepositoryImpl(this._apiService, this._storageService);

  @override
  Future<Profile> getProfile(String login) async {
    final data = await _apiService.fetchUserProfile(login);
    final dto = ProfileDto.fromJson(data);
    final password = await _storageService.read('user_password') ?? '';
    final entity = ProfileMapper.toEntity(dto, fallbackLogin: login);
    return entity.copyWith(
      motDePasse: password.isNotEmpty ? password : entity.motDePasse,
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileApiServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
