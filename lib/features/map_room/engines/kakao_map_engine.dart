import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao;

import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';

int _zoomToLevel(double zoom) => zoom.round().clamp(6, 21);

// ── 컨트롤러 ──────────────────────────────────────────────────────────────────

class _KakaoNativeController implements MapEngineController {
  _KakaoNativeController(MapCoordinate center)
      : _center = center;

  MapCoordinate _center;
  _KakaoMapViewState? _state;

  void _attach(_KakaoMapViewState state) => _state = state;
  void _detach(_KakaoMapViewState state) {
    if (_state == state) _state = null;
  }

  @override
  void move(MapCoordinate center, double zoom) {
    _center = center;
    _state?._move(center, zoom);
  }

  @override
  MapCoordinate get center => _center;

  @override
  Object get raw => this;
}

// ── 엔진 ──────────────────────────────────────────────────────────────────────

class KakaoMapEngine extends MapEngine {
  @override
  MapEngineController createController() =>
      _KakaoNativeController(const MapCoordinate(37.5665, 126.9780));

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
    final ctrl = controller as _KakaoNativeController;
    ctrl._center = initialCenter;
    return _KakaoMapView(
      controller: ctrl,
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      markers: markers,
      userLocation: userLocation,
      routePoints: routePoints,
      onMarkerTap: onMarkerTap,
      colorForMarker: markerColor,
    );
  }
}

// ── 뷰 ────────────────────────────────────────────────────────────────────────

class _KakaoMapView extends StatefulWidget {
  final _KakaoNativeController controller;
  final MapCoordinate initialCenter;
  final double initialZoom;
  final List<MapMarkerModel> markers;
  final MapCoordinate? userLocation;
  final List<MapCoordinate>? routePoints;
  final void Function(MapMarkerModel) onMarkerTap;
  final int Function(MapMarkerModel) colorForMarker;

  const _KakaoMapView({
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.markers,
    required this.userLocation,
    required this.routePoints,
    required this.onMarkerTap,
    required this.colorForMarker,
  });

  @override
  State<_KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<_KakaoMapView> {
  kakao.KakaoMapController? _native;
  final List<kakao.Poi> _activePois = [];
  kakao.Route? _activeRoute;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant _KakaoMapView old) {
    super.didUpdateWidget(old);
    final native = _native;
    if (native == null) return;
    if (widget.markers != old.markers ||
        widget.userLocation != old.userLocation) {
      _syncMarkers(native);
    }
    if (widget.routePoints != old.routePoints) {
      _syncRoute(native);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void _move(MapCoordinate center, double zoom) {
    _native?.moveCamera(
      kakao.CameraUpdate.newCenterPosition(
        kakao.LatLng(center.latitude, center.longitude),
        zoomLevel: _zoomToLevel(zoom),
      ),
    );
  }

  Future<void> _syncMarkers(kakao.KakaoMapController ctrl) async {
    if (_syncing) return;
    _syncing = true;
    try {
      // 기존 POI 삭제
      for (final poi in _activePois) {
        await ctrl.labelLayer.removePoi(poi);
      }
      _activePois.clear();

      final allMarkers = [
        ...widget.markers,
        if (widget.userLocation != null)
          MapMarkerModel(
            id: '__user__',
            location: widget.userLocation!,
            category: MarkerCategory.other,
            title: '',
            venue: '',
          ),
      ];

      for (final m in allMarkers) {
        if (!mounted) break;
        final isUser = m.id == '__user__';
        final color = isUser
            ? const Color(0xFF16213E)
            : Color(widget.colorForMarker(m));
        final size = isUser ? 20.0 : (m.isHighlighted ? 22.0 : 18.0);
        final borderWidth = isUser ? 3.0 : (m.isHighlighted ? 3.0 : 2.0);

        final icon = await kakao.KImage.fromWidget(
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: borderWidth),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          Size(size, size),
        );

        final poi = await ctrl.labelLayer.addPoi(
          kakao.LatLng(m.location.latitude, m.location.longitude),
          style: kakao.PoiStyle(icon: icon),
          onClick: isUser ? null : () => widget.onMarkerTap(m),
        );
        _activePois.add(poi);
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncRoute(kakao.KakaoMapController ctrl) async {
    final existing = _activeRoute;
    if (existing != null) {
      await ctrl.routeLayer.removeRoute(existing);
      _activeRoute = null;
    }
    final points = widget.routePoints;
    if (points == null || points.length < 2) return;
    _activeRoute = await ctrl.routeLayer.addRoute(
      points.map((p) => kakao.LatLng(p.latitude, p.longitude)).toList(),
      kakao.RouteStyle(const Color(0xFF16213E), 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return kakao.KakaoMap(
      option: kakao.KakaoMapOption(
        position: kakao.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoomLevel: _zoomToLevel(widget.initialZoom),
      ),
      onMapReady: (controller) {
        _native = controller;
        widget.controller._attach(this);
        _move(widget.controller._center, widget.initialZoom);
        _syncMarkers(controller);
        _syncRoute(controller);
      },
    );
  }
}
