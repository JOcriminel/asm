import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../services/auth_api_service.dart';
import '../../../profile/data/services/profile_api_service.dart';
import '../../../../core/services/storage_service.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> getCurrentUser(String token);
  Future<void> logout();
}

class HttpAuthRepository implements AuthRepository {
  final AuthApiService _authApiService;
  final ProfileApiService _profileApiService;
  final StorageService _storageService;

  static const _tokenKey = 'auth_token';

  HttpAuthRepository(
    this._authApiService,
    this._profileApiService,
    this._storageService,
  );

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    final payload = parts[1];
    final normalized = base64.normalize(payload);
    final resp = utf8.decode(base64.decode(normalized));
    return json.decode(resp) as Map<String, dynamic>;
  }

  @override
  Future<User> login(String username, String password) async {
    final tokenData = await _authApiService.login(username, password);
    final accessToken = tokenData['access_token'] as String? ?? '';
    
    if (accessToken.isEmpty) {
      throw Exception('Login succeeded but access token is missing');
    }

    // Write token first so subsequent network requests carry the authorization header
    await _storageService.write(_tokenKey, accessToken);
    await _storageService.write('user_password', password);

    try {
      final claims = _decodeJwt(accessToken);
      final loginName = claims['preferred_username'] as String? ?? username;

      // Fetch user profile from backend
      final userProfile = await _profileApiService.fetchUserProfile(loginName);
      final Map<String, dynamic> data = (userProfile.containsKey('0') && userProfile['0'] is Map<String, dynamic>)
          ? userProfile['0'] as Map<String, dynamic>
          : userProfile;

      final typeUser = data['typeUser'] as Map<String, dynamic>?;
      final typeUserLibelle = typeUser?['libelle']?.toString();

      return User(
        id: data['code']?.toString() ?? data['Code']?.toString() ?? claims['sub']?.toString() ?? 'unknown_id',
        username: data['login']?.toString() ?? data['Login']?.toString() ?? loginName,
        fullName: data['nomPrenom']?.toString() ?? data['Nom et prénom']?.toString() ?? data['fullName']?.toString() ?? claims['name']?.toString() ?? loginName,
        email: data['mail']?.toString() ?? data['Mail']?.toString() ?? data['email']?.toString() ?? claims['email']?.toString() ?? '',
        role: typeUserLibelle ?? data['typeUtilisateur']?.toString() ?? data['Type Utilisateur']?.toString() ?? (claims['realm_access']?['roles'] as List?)?.join(', ') ?? 'User',
        station: data['idStation']?.toString() ?? data['station']?.toString() ?? data['Station']?.toString() ?? 'Default Station',
        phone: data['tel']?.toString() ?? data['telephone']?.toString() ?? data['Téléphone']?.toString() ?? data['phone']?.toString() ?? '',
        tierId: data['idTier']?.toString() ?? data['idRepresentant']?.toString() ?? '',
      );
    } catch (e) {
      // Reset token if profile loading fails
      await _storageService.delete(_tokenKey);
      rethrow;
    }
  }

  @override
  Future<User> getCurrentUser(String token) async {
    final claims = _decodeJwt(token);
    final loginName = claims['preferred_username'] as String? ?? '';

    if (loginName.isEmpty) {
      throw Exception('Unable to decode session user');
    }

    final userProfile = await _profileApiService.fetchUserProfile(loginName);
    final Map<String, dynamic> data = (userProfile.containsKey('0') && userProfile['0'] is Map<String, dynamic>)
        ? userProfile['0'] as Map<String, dynamic>
        : userProfile;

    final typeUser = data['typeUser'] as Map<String, dynamic>?;
    final typeUserLibelle = typeUser?['libelle']?.toString();

    return User(
      id: data['code']?.toString() ?? data['Code']?.toString() ?? claims['sub']?.toString() ?? 'unknown_id',
      username: data['login']?.toString() ?? data['Login']?.toString() ?? loginName,
      fullName: data['nomPrenom']?.toString() ?? data['Nom et prénom']?.toString() ?? data['fullName']?.toString() ?? claims['name']?.toString() ?? loginName,
      email: data['mail']?.toString() ?? data['Mail']?.toString() ?? data['email']?.toString() ?? claims['email']?.toString() ?? '',
      role: typeUserLibelle ?? data['typeUtilisateur']?.toString() ?? data['Type Utilisateur']?.toString() ?? (claims['realm_access']?['roles'] as List?)?.join(', ') ?? 'User',
      station: data['idStation']?.toString() ?? data['station']?.toString() ?? data['Station']?.toString() ?? 'Default Station',
      phone: data['tel']?.toString() ?? data['telephone']?.toString() ?? data['Téléphone']?.toString() ?? data['phone']?.toString() ?? '',
      tierId: data['idTier']?.toString() ?? data['idRepresentant']?.toString() ?? '',
    );
  }

  @override
  Future<void> logout() async {
    await _storageService.delete(_tokenKey);
    await _storageService.delete('user_password');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApiService = ref.watch(authApiServiceProvider);
  final profileApiService = ref.watch(profileApiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return HttpAuthRepository(authApiService, profileApiService, storageService);
});
