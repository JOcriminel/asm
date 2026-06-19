import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/utils/logger.dart';

class UserRole {
  final String code;
  final String label;

  const UserRole({required this.code, required this.label});
}

final userRolesProvider = FutureProvider<List<UserRole>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    AppLogger.d('UserRolesProvider', 'Fetching roles from Typeuser/findall');
    final response = await dio.get('https://duxweb.pre-produx.asmtechtn.com/api/Typeuser/findall');
    
    if (response.data is List) {
      final list = response.data as List;
      final parsed = list.map((item) {
        final map = item as Map<String, dynamic>;
        
        // Find Typeuser code and display name (libelle / designation / code / id)
        final libelle = (map['libelle'] ?? map['libellé'] ?? map['designation'] ?? map['code'] ?? '').toString().trim();
        final id = (map['idTypeuser'] ?? map['id'] ?? libelle).toString().trim();
        
        return UserRole(
          code: libelle.isNotEmpty ? libelle : id,
          label: libelle.isNotEmpty ? libelle : id,
        );
      }).where((role) => role.code.isNotEmpty).toList();
      
      if (parsed.isNotEmpty) {
        AppLogger.d('UserRolesProvider', 'Successfully parsed ${parsed.length} user roles');
        return parsed;
      }
    }
  } catch (e, stack) {
    AppLogger.e('UserRolesProvider', 'Error fetching user roles: $e', stack);
  }

  // Fallback defaults in case of network or parsing failure
  AppLogger.d('UserRolesProvider', 'Returning fallback user roles');
  return const [
    UserRole(code: 'Administrateur', label: 'Administrateur'),
    UserRole(code: 'Commercial', label: 'Commercial'),
    UserRole(code: 'Opérateur', label: 'Opérateur'),
    UserRole(code: 'admin', label: 'admin'),
    UserRole(code: 'commercial', label: 'commercial'),
    UserRole(code: 'operateur', label: 'operateur'),
  ];
});
