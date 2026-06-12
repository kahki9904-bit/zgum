import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  // ── 지도 기본값 ───────────────────────────────────────────────────────────────

  /// 위치 권한 거부 시 기본 기준점: 서울 시청
  static const LatLng defaultLocation = LatLng(37.5665, 126.9780);

  /// 기본 탐색 반경 (km)
  static const double defaultRadiusKm = 20.0;

  /// 카카오맵 기본 줌 레벨 (6=가장 축소, 21=가장 확대 / 18 = 반경 250m)
  static const double defaultZoom = 18.0;

  /// 앱 이름
  static const String appName = 'Z:GUM';
}
