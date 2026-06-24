import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao;

import '../../../core/interfaces/map_engine.dart';
import '../../../core/map_marker_layout.dart';
import '../../../core/models/map_marker_model.dart';

int _zoomToLevel(double zoom) => zoom.round().clamp(6, 21);

// ── 컨트롤러 ──────────────────────────────────────────────────────────────────

class _KakaoNativeController implements MapEngineController {
  _KakaoNativeController(MapCoordinate center) : _center = center;

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
    if (widget.userLocation != old.userLocation) {
      _syncUserMarker(native);
    }
    if (widget.markers != old.markers) {
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

  // 이벤트/검색 마커 비트맵 캐시
  final Map<int, kakao.KImage> _markerImages = {};

  Future<kakao.KImage> _getMarkerImage(MapMarkerModel marker) async {
    final isSearch = _isSearchMarker(marker);
    final fillColor =
        isSearch ? Colors.white : Color(widget.colorForMarker(marker));
    final borderColor =
        isSearch ? Color(widget.colorForMarker(marker)) : Colors.white;
    final centerColor = isSearch
        ? Color(widget.colorForMarker(marker))
        : const Color(0xFF9EEEFF);
    final cacheKey = Object.hash(
      fillColor.toARGB32(),
      borderColor.toARGB32(),
      centerColor.toARGB32(),
    );
    final cached = _markerImages[cacheKey];
    if (cached != null) return cached;
    final spec = MapMarkerLayoutSpec.current;
    final double tapSize = spec.bitmapSize;
    final markerWidget = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: tapSize,
        height: tapSize,
        child: Center(
          child: _KakaoDropMarker(
            fillColor: fillColor,
            borderColor: borderColor,
            centerColor: centerColor,
          ),
        ),
      ),
    );
    final image =
        await kakao.KImage.fromWidget(markerWidget, Size(tapSize, tapSize));
    _markerImages[cacheKey] = image;
    return image;
  }

  // 내 위치 마커 비트맵 캐시
  kakao.KImage? _userMarkerImage;
  kakao.Poi? _userLocationPoi;
  bool _syncingUserMarker = false;

  Future<kakao.KImage> _getUserMarkerImage() async {
    if (_userMarkerImage != null) return _userMarkerImage!;
    final spec = MapMarkerLayoutSpec.current;
    final double tapSize = spec.bitmapSize;
    final markerWidget = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: tapSize,
        height: tapSize,
        child: Center(
          child: _KakaoDropMarker(
            fillColor: const Color(0xFF52606C),
            borderColor: Colors.white,
            centerColor: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
    _userMarkerImage =
        await kakao.KImage.fromWidget(markerWidget, Size(tapSize, tapSize));
    return _userMarkerImage!;
  }

  Future<void> _syncUserMarker(kakao.KakaoMapController ctrl) async {
    if (_syncingUserMarker) return;
    _syncingUserMarker = true;
    try {
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
    } finally {
      _syncingUserMarker = false;
    }
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
      for (final m in markersToSync) {
        if (!mounted) break;
        final icon = await _getMarkerImage(m);
        final poi = await ctrl.labelLayer.addPoi(
          kakao.LatLng(m.location.latitude, m.location.longitude),
          style: kakao.PoiStyle(icon: icon),
          onClick: () {
            debugPrint('[KakaoMap] marker tapped: ${m.id} / ${m.title}');
            widget.onMarkerTap(m);
          },
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

  bool _isSearchMarker(MapMarkerModel marker) =>
      marker.category == MarkerCategory.other ||
      marker.category == MarkerCategory.cinema;

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

  void _handleIosMapTap(kakao.LatLng position) {
    if (!Platform.isIOS || widget.markers.isEmpty) return;

    MapMarkerModel? nearest;
    var nearestMeters = double.infinity;

    for (final marker in widget.markers) {
      final meters = _distanceMeters(
        position.latitude,
        position.longitude,
        marker.location.latitude,
        marker.location.longitude,
      );
      if (meters < nearestMeters) {
        nearestMeters = meters;
        nearest = marker;
      }
    }

    if (nearest == null || nearestMeters > 70) return;
    debugPrint(
      '[KakaoMap] iOS map tap fallback: ${nearest.id} / ${nearest.title} / ${nearestMeters.toStringAsFixed(1)}m',
    );
    widget.onMarkerTap(nearest);
  }

  double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;

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
        _syncUserMarker(controller);
        _syncMarkers(controller);
        _syncRoute(controller);
        widget.onEngineReady?.call();
      },
      onMapClick: (_, position) => _handleIosMapTap(position),
      onTerrainClick: (_, position) => _handleIosMapTap(position),
    );
  }
}

class _KakaoDropMarker extends StatelessWidget {
  const _KakaoDropMarker({
    required this.fillColor,
    required this.borderColor,
    required this.centerColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color centerColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398,
      child: Container(
        width: MapMarkerLayoutSpec.current.pinSize,
        height: MapMarkerLayoutSpec.current.pinSize,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(999),
            topRight: const Radius.circular(999),
            bottomLeft: const Radius.circular(999),
            bottomRight:
                Radius.circular(MapMarkerLayoutSpec.current.tailRadius),
          ),
          border: Border.all(
            color: borderColor,
            width: MapMarkerLayoutSpec.current.borderWidth,
          ),
          boxShadow: MapMarkerLayoutSpec.current.shadowBlur <= 0
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: MapMarkerLayoutSpec.current.shadowBlur,
                    offset: Offset(
                      0,
                      MapMarkerLayoutSpec.current.shadowOffsetY,
                    ),
                  ),
                ],
        ),
        child: Center(
          child: Container(
            width: MapMarkerLayoutSpec.current.centerSize,
            height: MapMarkerLayoutSpec.current.centerSize,
            decoration: BoxDecoration(
              color: centerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: fillColor == Colors.white
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.84),
                width: MapMarkerLayoutSpec.current.borderWidth * 0.75,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
