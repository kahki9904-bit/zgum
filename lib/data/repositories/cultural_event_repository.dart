import 'package:latlong2/latlong.dart';
import '../models/cultural_event.dart';

abstract class CulturalEventRepository {
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  });
}
