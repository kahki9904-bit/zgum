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

  /// 마커 색상 (ARGB int) — 내 위치는 각 엔진에서 별도 처리,
  /// 지도 이벤트는 하나의 이벤트 색상으로 묶고 검색 핀만 분리합니다.
  /// 색상 변경 시 이 메서드만 수정하면 됩니다.
  int markerColor(MapMarkerModel marker) {
    if (marker.isExpired()) {
      return 0xFF8A7A67;
    }
    if (marker.isPartner) {
      return 0xFFB9782E;
    }
    if (marker.category == MarkerCategory.cinema ||
        marker.category == MarkerCategory.other) {
      return 0xFF222831;
    }
    return 0xFF263F3B;
  }
}
