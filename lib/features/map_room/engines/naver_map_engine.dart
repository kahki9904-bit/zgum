import 'package:flutter/material.dart';

import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';

/// 네이버 지도 SDK 연동 스텁.
///
/// ## 연동 방법
/// 1. pubspec.yaml 에 `flutter_naver_map` 패키지 추가
/// 2. AndroidManifest.xml 에 네이버 지도 클라이언트 ID 설정
/// 3. 아래 TODO 위치에 실제 구현 작성
class NaverMapEngine extends MapEngine {
  @override
  MapEngineController createController() {
    // TODO: NaverMapController 래퍼 반환
    throw UnimplementedError('NaverMapEngine: createController() 미구현');
  }

  @override
  Widget buildWidget({
    required MapCoordinate initialCenter,
    required double initialZoom,
    required List<MapMarkerModel> markers,
    required void Function(MapMarkerModel marker) onMarkerTap,
    required MapEngineController controller,
    VoidCallback? onEngineReady,
    MapCoordinate? userLocation,
    List<MapCoordinate>? routePoints,
  }) {
    // TODO: NaverMap 위젯 반환
    throw UnimplementedError('NaverMapEngine: buildWidget() 미구현');
  }
}
