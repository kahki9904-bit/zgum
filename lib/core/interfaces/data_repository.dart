import 'package:latlong2/latlong.dart';

import '../models/map_marker_model.dart';

/// 데이터 소스에 독립적인 근처 데이터 조회 인터페이스.
///
/// ## 보안 설계 원칙
/// [isAdultVerified] 를 Repository 단에서 처리합니다.
/// UI 는 반환된 데이터를 그대로 렌더링하면 되며,
/// 성인 콘텐츠 필터링 로직을 화면 레이어에 두지 않습니다.
abstract class DataRepository {
  /// [center] 기준 [radiusKm] 반경 내 데이터를 반환합니다.
  ///
  /// [isAdultVerified] 가 false 이면 Repository 에서 성인 전용 항목을 제거한
  /// 깨끗한 리스트를 반환합니다. UI 는 별도 필터 없이 결과를 바로 사용하세요.
  Future<List<MapMarkerModel>> fetchNearbyData({
    required LatLng center,
    required double radiusKm,
    required bool isAdultVerified,
    String? query,
  });
}
