import '../../domain/models/profile.dart';
import '../models/profile_dto.dart';

class ProfileMapper {
  static Profile toEntity(ProfileDto dto, {String? fallbackLogin}) {
    return Profile(
      userId: (dto.login != null && dto.login!.isNotEmpty) ? dto.login! : (fallbackLogin ?? ''),
      fullName: dto.nomEtPrenom ?? '',
      email: dto.mail ?? '',
      role: dto.typeUtilisateur ?? 'User',
      station: dto.station ?? '',
      phone: dto.telephone ?? '',
      location: dto.cellule ?? '',
      employeeId: dto.code ?? '',
      joinedDate: dto.dateCreation != null
          ? DateTime.tryParse(dto.dateCreation!) ?? DateTime.now()
          : DateTime.now(),
      cellule: dto.cellule ?? '',
      createur: dto.createur ?? '',
      isActive: dto.active == '1' || dto.active?.toLowerCase() == 'true',
      isSuperAdmin: dto.superAdmin == '1' || dto.superAdmin?.toLowerCase() == 'true',
      motDePasse: dto.motDePasse ?? '',
    );
  }
}
