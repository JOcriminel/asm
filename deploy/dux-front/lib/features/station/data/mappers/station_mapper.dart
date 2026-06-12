import '../../domain/models/station.dart';
import '../models/station_dto.dart';

class StationMapper {
  static Station toEntity(StationDto dto) {
    return Station(
      id: dto.id ?? '',
      name: dto.name ?? 'Unknown Station',
      code: dto.code ?? 'N/A',
      address: dto.address ?? 'No address information available',
      region: dto.region ?? 'Unknown Region',
      phone: dto.phone ?? 'N/A',
      fax: dto.fax ?? 'N/A',
      email: dto.email ?? 'N/A',
      managerName: dto.managerName ?? 'N/A',
      typeStation: dto.typeStation ?? 'N/A',
      matriculeFiscal: dto.matriculeFiscal ?? 'N/A',
      logo: dto.logo ?? '',
      active: dto.active ?? '1',
      workingHours: dto.workingHours ?? 'N/A',
      capacity: dto.capacity ?? 0,
      latitude: dto.latitude ?? 0.0,
      longitude: dto.longitude ?? 0.0,
    );
  }
}
