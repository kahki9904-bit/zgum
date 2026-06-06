import 'package:flutter/material.dart';

import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';

/// 카카오 지도 SDK 연동 스텁.
///
/// ## 연동 방법
/// 1. pubspec.yaml 에 `kakao_map_plugin` 패키지 추가
/// 2. AndroidManifest.xml 에 카카오 앱 키 설정
/// 3. 아래 TODO 위치에 실제 구현 작성
class KakaoMapEngine extends MapEngine {
  @override
  MapEngineController createController() {
    // TODO: KakaoMapController 래퍼 반환
    throw UnimplementedError('KakaoMapEngine: createController() 미구현');
  }

  @override
  Widget buildWidget({
    required MapCoordinate initialCenter,
    required double initialZoom,
    required List<MapMarkerModel> markers,
    required void Function(MapMarkerModel marker) onMarkerTap,
    required MapEngineController controller,
    MapCoordinate? userLocation,
    List<MapCoordinate>? routePoints,
  }) {
    // TODO: KakaoMap 위젯 반환
    throw UnimplementedError('KakaoMapEngine: buildWidget() 미구현');
  }
}
