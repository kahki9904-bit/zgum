import 'package:flutter/widgets.dart';
import '../models/map_marker_model.dart';

// ── 컨트롤러 추상 ──────────────────────────────────────────────────────────────

/// 지도 카메라를 프로그래밍적으로 제어하는 추상 인터페이스.
///
/// flutter_map 의 MapController, 네이버/카카오의 각 컨트롤러 모두
/// 이 인터페이스로 감싸서 사용합니다.
abstract class MapEngineController {
  void move(MapCoordinate center, double zoom);
  MapCoordinate get center;

  /// 엔진 내부 원본 컨트롤러. 타입 캐스팅이 필요한 경우에만 사용하세요.
  Object get raw;
}

// ── 엔진 추상 ──────────────────────────────────────────────────────────────────

/// 지도 렌더링 엔진 추상 인터페이스.
///
/// ## 교체 방법
/// MapRoomScreen 의 `_engine` 필드 한 줄만 바꾸면 됩니다.
/// ```dart
/// final MapEngine _engine = FlutterMapEngine(); // 현재
/// final MapEngine _engine = NaverMapEngine();   // 네이버로 교체
/// ```
abstract class MapEngine {
  MapEngineController createController();

  Widget buildWidget({
    required MapCoordinate initialCenter,
    required double initialZoom,
    required List<MapMarkerModel> markers,
    required void Function(MapMarkerModel marker) onMarkerTap,
    required MapEngineController controller,
    MapCoordinate? userLocation,
    List<MapCoordinate>? routePoints,
    VoidCallback? onEngineReady,
  });

  /// 마커 카테고리에 따른 색상 (ARGB int). 엔진별로 오버라이드 가능.
  int markerColor(MapMarkerModel marker) {
    if (marker.isAdultOnly) return 0xFFFF4C7D;
    if (marker.isPartner) return 0xFFFF8C00;
    return switch (marker.category) {
      MarkerCategory.movie => 0xFF2196F3,
      MarkerCategory.theater => 0xFF9C27B0,
      MarkerCategory.exhibition => 0xFFFFC107,
      MarkerCategory.show => 0xFF4CAF50,
      MarkerCategory.concert => 0xFFF44336,
      MarkerCategory.sale => 0xFFFF8C00,
      MarkerCategory.cinema => 0xFF0D47A1,
      MarkerCategory.partner => 0xFFFF8C00,
      MarkerCategory.other => 0xFF00BCD4,
    };
  }
}
