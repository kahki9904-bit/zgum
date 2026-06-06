import 'package:latlong2/latlong.dart';
import '../models/cinema_model.dart';

abstract class CinemaRepository {
  Future<List<CinemaModel>> fetchNearbyCinemas({
    required LatLng center,
    required double radiusKm,
  });
}
