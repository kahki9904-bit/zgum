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
    VoidCallback? onEngineReady,
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
      onEngineReady: onEngineReady,
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
  final VoidCallback? onEngineReady;

  const _KakaoMapView({
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.markers,
    required this.userLocation,
    required this.routePoints,
    required this.onMarkerTap,
    required this.colorForMarker,
    this.onEngineReady,
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
    if (widget.markers != old.markers) {
      _syncMarkers(native);
    }
    if (widget.userLocation != old.userLocation) {
      _syncUserMarker(native);
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

  // 이벤트 마커 비트맵 캐시
  kakao.KImage? _markerImage;

  Future<kakao.KImage> _getMarkerImage() async {
    if (_markerImage != null) return _markerImage!;
    const double iconSize = 20.0;
    const double tapSize = 44.0;
    const markerWidget = SizedBox(
      width: tapSize,
      height: tapSize,
      child: Center(
        child: Icon(Icons.location_on, size: iconSize),
      ),
    );
    _markerImage = await kakao.KImage.fromWidget(markerWidget, const Size(tapSize, tapSize));
    return _markerImage!;
  }

  // 내 위치 마커 비트맵 캐시
  kakao.KImage? _userMarkerImage;
  kakao.Poi? _userLocationPoi;

  Future<kakao.KImage> _getUserMarkerImage() async {
    if (_userMarkerImage != null) return _userMarkerImage!;
    const double iconSize = 28.0;
    const double tapSize = 44.0;
    const markerWidget = SizedBox(
      width: tapSize,
      height: tapSize,
      child: Center(
        child: Icon(Icons.location_on, size: iconSize),
      ),
    );
    _userMarkerImage = await kakao.KImage.fromWidget(markerWidget, const Size(tapSize, tapSize));
    return _userMarkerImage!;
  }

  Future<void> _syncUserMarker(kakao.KakaoMapController ctrl) async {
    final existing = _userLocationPoi;
    if (existing != null) {
      await ctrl.labelLayer.removePoi(existing);
      _userLocationPoi = null;
    }
    final loc = widget.userLocation;
    if (loc == null) return;
    final icon = await _getUserMarkerImage();
    _userLocationPoi = await ctrl.labelLayer.addPoi(
      kakao.LatLng(loc.latitude, loc.longitude),
      style: kakao.PoiStyle(icon: icon),
    );
  }

  List<MapMarkerModel>? _pendingMarkers;

  Future<void> _syncMarkers(kakao.KakaoMapController ctrl) async {
    if (_syncing) {
      _pendingMarkers = List.of(widget.markers);
      return;
    }
    _syncing = true;
    _pendingMarkers = null;
    try {
      for (final poi in _activePois) {
        await ctrl.labelLayer.removePoi(poi);
      }
      _activePois.clear();

      final markersToSync = List.of(widget.markers);
      final icon = await _getMarkerImage();
      for (final m in markersToSync) {
        if (!mounted) break;
        final poi = await ctrl.labelLayer.addPoi(
          kakao.LatLng(m.location.latitude, m.location.longitude),
          style: kakao.PoiStyle(icon: icon),
          onClick: () => widget.onMarkerTap(m),
        );
        _activePois.add(poi);
      }
    } finally {
      _syncing = false;
      final pending = _pendingMarkers;
      if (pending != null && mounted) {
        _pendingMarkers = null;
        _syncMarkers(ctrl);
      }
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
        _syncUserMarker(controller);
        _syncRoute(controller);
        widget.onEngineReady?.call();
      },
    );
  }
}

