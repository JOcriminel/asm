import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../services/station_api_service.dart';
import '../models/station_dto.dart';
import '../mappers/station_mapper.dart';

/// Concrete implementation of [StationRepository].
class StationRepositoryImpl implements StationRepository {
  final StationApiService _apiService;

  const StationRepositoryImpl(this._apiService);

  @override
  Future<Station> getStation(String id) async {
    final data = await _apiService.fetchStation(id);
    final dto = StationDto.fromJson(data);
    return StationMapper.toEntity(dto);
  }
}

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepositoryImpl(ref.watch(stationApiServiceProvider));
});
