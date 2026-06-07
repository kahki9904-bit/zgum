import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';

// ── 좌표 변환 ─────────────────────────────────────────────────────────────────

extension _ToKakao on MapCoordinate {
  kakao.LatLng toKakao() => kakao.LatLng(latitude, longitude);
}

// flutter_map zoom(높을수록 확대) → kakao level(낮을수록 확대)
int _toKakaoLevel(double zoom) => (18 - zoom).round().clamp(1, 14);

// ── 마커 이미지 (SVG → base64 data URL) ───────────────────────────────────────

String _svgPinUrl(Color color) {
  int toHex(double c) => (c * 255.0).round().clamp(0, 255);
  final hex = '#'
      '${toHex(color.r).toRadixString(16).padLeft(2, '0')}'
      '${toHex(color.g).toRadixString(16).padLeft(2, '0')}'
      '${toHex(color.b).toRadixString(16).padLeft(2, '0')}';
  final svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="30" viewBox="0 0 24 30">'
      '<path d="M12 0C5.37 0 0 5.37 0 12c0 9 12 18 12 18s12-9 12-18C24 5.37 18.63 0 12 0z" fill="$hex"/>'
      '<circle cx="12" cy="12" r="4.5" fill="white" opacity="0.7"/>'
      '</svg>';
  return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
}

String _svgUserDotUrl() {
  const svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">'
      '<circle cx="10" cy="10" r="8" fill="#16213E" stroke="white" stroke-width="3"/>'
      '<circle cx="10" cy="10" r="3" fill="white"/>'
      '</svg>';
  return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
}

// ── 컨트롤러 ──────────────────────────────────────────────────────────────────

class _KakaoMapController implements MapEngineController {
  kakao.KakaoMapController? _inner;
  MapCoordinate _center;

  _KakaoMapController(this._center);

  void _attach(kakao.KakaoMapController inner) {
    _inner = inner;
  }

  void _syncCenter(MapCoordinate c) {
    _center = c;
  }

  @override
  void move(MapCoordinate center, double zoom) {
    _center = center;
    _inner?.setCenter(center.toKakao());
    _inner?.setLevel(_toKakaoLevel(zoom));
  }

  @override
  MapCoordinate get center => _center;

  @override
  Object get raw => _inner ?? this;
}

// ── 엔진 ──────────────────────────────────────────────────────────────────────

class KakaoMapEngine extends MapEngine {
  @override
  MapEngineController createController() {
    return _KakaoMapController(
      const MapCoordinate(37.5665, 126.9780),
    );
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
    final ctrl = controller as _KakaoMapController;
    ctrl._syncCenter(initialCenter);

    final userDotUrl = _svgUserDotUrl();
    final kakaoMarkers = <kakao.Marker>[];

    if (userLocation != null) {
      kakaoMarkers.add(kakao.Marker(
        markerId: '__user__',
        latLng: userLocation.toKakao(),
        // ignore: deprecated_member_use
        markerImageSrc: userDotUrl,
        width: 20,
        height: 20,
        offsetX: 10,
        offsetY: 10,
      ));
    }

    for (final m in markers) {
      final color = Color(markerColor(m));
      final w = m.isPartner ? 28 : 24;
      final h = m.isPartner ? 35 : 30;
      kakaoMarkers.add(kakao.Marker(
        markerId: m.id,
        latLng: m.location.toKakao(),
        // ignore: deprecated_member_use
        markerImageSrc: _svgPinUrl(color),
        width: w,
        height: h,
        offsetX: w ~/ 2,
        offsetY: h,
      ));
    }

    final kakaoPolylines = <kakao.Polyline>[];
    if (routePoints != null && routePoints.isNotEmpty) {
      kakaoPolylines.add(kakao.Polyline(
        polylineId: 'route',
        points: routePoints.map((c) => c.toKakao()).toList(),
        strokeColor: const Color(0xFF16213E),
        strokeWidth: 4,
        strokeOpacity: 0.9,
      ));
    }

    return kakao.KakaoMap(
      onMapCreated: ctrl._attach,
      center: initialCenter.toKakao(),
      currentLevel: _toKakaoLevel(initialZoom),
      markers: kakaoMarkers,
      polylines: kakaoPolylines.isEmpty ? null : kakaoPolylines,
      onMarkerTap: (markerId, latLng, zoomLevel) {
        if (markerId == '__user__') return;
        final matched = markers.where((m) => m.id == markerId).firstOrNull;
        if (matched != null) onMarkerTap(matched);
      },
    );
  }
}
