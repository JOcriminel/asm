import '../../domain/models/station.dart';

/// Domain port for station data.
abstract class StationRepository {
  Future<Station> getStation(String id);
}
