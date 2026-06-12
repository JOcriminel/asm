import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/station.dart';
import '../services/station_api_service.dart';
import '../models/station_dto.dart';
import '../mappers/station_mapper.dart';

abstract class StationRepository {
  Future<Station> getStation(String id);
}

class HttpStationRepository implements StationRepository {
  final StationApiService _apiService;

  HttpStationRepository(this._apiService);

  @override
  Future<Station> getStation(String id) async {
    final data = await _apiService.fetchStation(id);
    final dto = StationDto.fromJson(data);
    return StationMapper.toEntity(dto);
  }
}

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final apiService = ref.watch(stationApiServiceProvider);
  return HttpStationRepository(apiService);
});
