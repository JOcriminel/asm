import '../../domain/models/station.dart';
import '../../domain/repositories/station_repository.dart';

/// Use-case: retrieve station details by ID.
class GetStationUseCase {
  final StationRepository _repository;

  const GetStationUseCase(this._repository);

  Future<Station> call(String id) => _repository.getStation(id);
}
