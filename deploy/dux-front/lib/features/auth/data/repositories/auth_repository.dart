import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_api_service.dart';
import '../utils/jwt_decoder.dart';
import '../../../profile/data/services/profile_api_service.dart';
import '../../../../core/services/storage_service.dart';

/// Concrete implementation of [AuthRepository].
/// Responsibility: HTTP login, token storage, user profile hydration.
/// JWT decoding is delegated to [JwtDecoder] (Single Responsibility).
class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _authApiService;
  final ProfileApiService _profileApiService;
  final StorageService _storageService;

  static const _tokenKey = 'auth_token';

  const AuthRepositoryImpl(
    this._authApiService,
    this._profileApiService,
    this._storageService,
  );

  @override
  Future<User> login(String username, String password) async {
    final tokenData = await _authApiService.login(username, password);
    final accessToken = tokenData['access_token'] as String? ?? '';

    if (accessToken.isEmpty) {
      throw Exception('Login succeeded but access token is missing');
    }

    await _storageService.write(_tokenKey, accessToken);
    await _storageService.write('user_password', password);

    try {
      final claims = JwtDecoder.decode(accessToken);
      final loginName = claims['preferred_username'] as String? ?? username;
      return await _buildUser(loginName, claims);
    } catch (e) {
      await _storageService.delete(_tokenKey);
      rethrow;
    }
  }

  @override
  Future<User> getCurrentUser(String token) async {
    final claims = JwtDecoder.decode(token);
    final loginName = claims['preferred_username'] as String? ?? '';
    if (loginName.isEmpty) throw Exception('Unable to decode session user');
    return _buildUser(loginName, claims);
  }

  @override
  Future<void> logout() async {
    await _storageService.delete(_tokenKey);
    await _storageService.delete('user_password');
  }

  /// Fetches the DUX ERP user profile and maps it to a [User] entity.
  Future<User> _buildUser(
    String loginName,
    Map<String, dynamic> claims,
  ) async {
    final userProfile = await _profileApiService.fetchUserProfile(loginName);
    final Map<String, dynamic> data =
        (userProfile.containsKey('0') && userProfile['0'] is Map<String, dynamic>)
            ? userProfile['0'] as Map<String, dynamic>
            : userProfile;

    final typeUser = data['typeUser'] as Map<String, dynamic>?;
    final typeUserLibelle = typeUser?['libelle']?.toString();

    return User(
      id: data['code']?.toString() ??
          data['Code']?.toString() ??
          claims['sub']?.toString() ??
          'unknown_id',
      username: data['login']?.toString() ??
          data['Login']?.toString() ??
          loginName,
      fullName: data['nomPrenom']?.toString() ??
          data['Nom et prénom']?.toString() ??
          data['fullName']?.toString() ??
          claims['name']?.toString() ??
          loginName,
      email: data['mail']?.toString() ??
          data['Mail']?.toString() ??
          data['email']?.toString() ??
          claims['email']?.toString() ??
          '',
      role: typeUserLibelle ??
          data['typeUtilisateur']?.toString() ??
          data['Type Utilisateur']?.toString() ??
          (claims['realm_access']?['roles'] as List?)?.join(', ') ??
          'User',
      station: data['idStation']?.toString() ??
          data['station']?.toString() ??
          data['Station']?.toString() ??
          'Default Station',
      phone: data['tel']?.toString() ??
          data['telephone']?.toString() ??
          data['Téléphone']?.toString() ??
          data['phone']?.toString() ??
          '',
      tierId: data['idTier']?.toString() ??
          data['idRepresentant']?.toString() ??
          '',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authApiServiceProvider),
    ref.watch(profileApiServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
