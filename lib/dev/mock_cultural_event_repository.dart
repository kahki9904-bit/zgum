import 'package:latlong2/latlong.dart';

import '../data/models/cultural_event.dart';
import '../data/repositories/cultural_event_repository.dart';

/// 공공데이터포털 API 키가 없을 때 앱이 빈 목록으로 동작하도록 하는 대체 저장소.
/// 화면 검수용 하드코딩 이벤트는 넣지 않습니다.
class MockCulturalEventRepository implements CulturalEventRepository {
  @override
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  }) async {
    return const [];
  }
}
