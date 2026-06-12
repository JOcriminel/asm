import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/profile.dart';
import '../services/profile_api_service.dart';
import '../models/profile_dto.dart';
import '../mappers/profile_mapper.dart';
import '../../../../core/services/storage_service.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile(String login);
}

class HttpProfileRepository implements ProfileRepository {
  final ProfileApiService _apiService;
  final StorageService _storageService;

  HttpProfileRepository(this._apiService, this._storageService);

  @override
  Future<Profile> getProfile(String login) async {
    final data = await _apiService.fetchUserProfile(login);
    final dto = ProfileDto.fromJson(data);
    final password = await _storageService.read('user_password') ?? '';
    
    final entity = ProfileMapper.toEntity(dto, fallbackLogin: login);
    return entity.copyWith(motDePasse: password.isNotEmpty ? password : entity.motDePasse);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiService = ref.watch(profileApiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return HttpProfileRepository(apiService, storageService);
});
