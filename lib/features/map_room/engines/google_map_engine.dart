import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/interfaces/map_engine.dart';
import '../../../core/map_marker_layout.dart';
import '../../../core/models/map_marker_model.dart';

// ── 지도 스타일 (도로 밝게) ──────────────────────────────────────────────────────
const _mapStyle = '''
[
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e0e0e0"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#f5f0e8"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e0d8c8"}]},
  {"featureType":"road","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#ede8e0"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#c8c0b8"}]}
]
''';

// ── 컨트롤러 ──────────────────────────────────────────────────────────────────

class _GoogleController implements MapEngineController {
  _GoogleController(MapCoordinate center) : _center = center;

  MapCoordinate _center;
  GoogleMapController? _native;

  @override
  void move(MapCoordinate center, double zoom) {
    _center = center;
    _native?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(center.latitude, center.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  MapCoordinate get center => _center;

  @override
  Object get raw => this;
}

// ── 엔진 ──────────────────────────────────────────────────────────────────────

class GoogleMapEngine extends MapEngine {
  @override
  MapEngineController createController() =>
      _GoogleController(const MapCoordinate(37.5665, 126.9780));

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
    final ctrl = controller as _GoogleController;
    ctrl._center = initialCenter;
    return _GoogleMapView(
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

class _GoogleMapView extends StatefulWidget {
  final _GoogleController controller;
  final MapCoordinate initialCenter;
  final double initialZoom;
  final List<MapMarkerModel> markers;
  final MapCoordinate? userLocation;
  final List<MapCoordinate>? routePoints;
  final void Function(MapMarkerModel) onMarkerTap;
  final int Function(MapMarkerModel) colorForMarker;
  final VoidCallback? onEngineReady;

  const _GoogleMapView({
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
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final Map<int, BitmapDescriptor> _bitmapCache = {};
  BitmapDescriptor? _userBitmap;
  Set<Marker> _gMarkers = {};
  Set<Polyline> _polylines = {};
  bool _building = false;
  List<MapMarkerModel>? _pending;
  double _dpr = 2.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newDpr = MediaQuery.devicePixelRatioOf(context);
    if (newDpr != _dpr) {
      _dpr = newDpr;
      _bitmapCache.clear();
      _userBitmap = null;
    }
  }

  @override
  void didUpdateWidget(covariant _GoogleMapView old) {
    super.didUpdateWidget(old);
    if (widget.markers != old.markers ||
        widget.userLocation != old.userLocation) {
      _rebuildMarkers();
    }
    if (widget.routePoints != old.routePoints) {
      _rebuildRoute();
    }
  }

  @override
  void dispose() {
    widget.controller._native?.dispose();
    super.dispose();
  }

  void _rebuildRoute() {
    final points = widget.routePoints;
    if (points == null || points.length < 2) {
      if (mounted) setState(() => _polylines = {});
      return;
    }
    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF16213E),
            width: 4,
            points:
                points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          ),
        };
      });
    }
  }

  bool _isSearchMarker(MapMarkerModel marker) =>
      marker.category == MarkerCategory.other ||
      marker.category == MarkerCategory.cinema;

  Future<BitmapDescriptor> _getMarkerBitmap(MapMarkerModel marker) async {
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
    if (_bitmapCache.containsKey(cacheKey)) return _bitmapCache[cacheKey]!;
    final bitmap = await _buildDropBitmap(
      fillColor: fillColor,
      borderColor: borderColor,
      centerColor: centerColor,
    );
    _bitmapCache[cacheKey] = bitmap;
    return bitmap;
  }

  Future<BitmapDescriptor> _getUserBitmap() async {
    if (_userBitmap != null) return _userBitmap!;
    _userBitmap = await _buildDropBitmap(
      fillColor: const Color(0xFF52606C),
      borderColor: Colors.white,
      centerColor: Colors.white.withValues(alpha: 0.78),
    );
    return _userBitmap!;
  }

  Future<BitmapDescriptor> _buildDropBitmap({
    required Color fillColor,
    required Color borderColor,
    required Color centerColor,
  }) async {
    final spec = MapMarkerLayoutSpec.current;
    final double size = spec.bitmapSize;
    final double pinS = spec.pinSize;
    final double cx = size / 2;
    final double cy = size / 2;
    final int imgSize = (size * _dpr).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size * _dpr, size * _dpr),
    );
    canvas.scale(_dpr);

    // 그림자
    if (spec.shadowBlur > 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter =
            ui.MaskFilter.blur(ui.BlurStyle.normal, spec.shadowBlur / 2);
      canvas.save();
      canvas.translate(cx, cy + spec.shadowOffsetY * 0.5);
      canvas.rotate(-math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset.zero, width: pinS, height: pinS),
          topLeft: Radius.circular(pinS / 2),
          topRight: Radius.circular(pinS / 2),
          bottomLeft: Radius.circular(pinS / 2),
          bottomRight: Radius.circular(spec.tailRadius),
        ),
        shadowPaint,
      );
      canvas.restore();
    }

    // 핀 몸통
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-math.pi / 4);
    final rrect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset.zero, width: pinS, height: pinS),
      topLeft: Radius.circular(pinS / 2),
      topRight: Radius.circular(pinS / 2),
      bottomLeft: Radius.circular(pinS / 2),
      bottomRight: Radius.circular(spec.tailRadius),
    );
    canvas.drawRRect(rrect, Paint()..color = fillColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.borderWidth,
    );
    canvas.restore();

    // 중앙 원
    canvas.drawCircle(
      Offset(cx, cy),
      spec.centerSize / 2,
      Paint()..color = centerColor,
    );
    if (fillColor != Colors.white) {
      canvas.drawCircle(
        Offset(cx, cy),
        spec.centerSize / 2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.84)
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec.borderWidth * 0.75,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(imgSize, imgSize);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: _dpr);
  }

  Future<void> _rebuildMarkers() async {
    if (_building) {
      _pending = List.of(widget.markers);
      return;
    }
    _building = true;
    _pending = null;
    try {
      final result = <Marker>{};

      final loc = widget.userLocation;
      if (loc != null) {
        final icon = await _getUserBitmap();
        result.add(Marker(
          markerId: const MarkerId('__user__'),
          position: LatLng(loc.latitude, loc.longitude),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 0,
        ));
      }

      for (final m in List.of(widget.markers)) {
        if (!mounted) break;
        final icon = await _getMarkerBitmap(m);
        result.add(Marker(
          markerId: MarkerId(m.id),
          position: LatLng(m.location.latitude, m.location.longitude),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
          onTap: () {
            debugPrint('[GoogleMap] marker tapped: ${m.id} / ${m.title}');
            widget.onMarkerTap(m);
          },
        ));
      }

      if (mounted) setState(() => _gMarkers = result);
    } finally {
      _building = false;
      final p = _pending;
      if (p != null && mounted) {
        _pending = null;
        _rebuildMarkers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      markers: _gMarkers,
      polylines: _polylines,
      style: _mapStyle,
      buildingsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        widget.controller._native = controller;
        widget.controller._center = widget.initialCenter;
        _rebuildMarkers();
        _rebuildRoute();
        widget.onEngineReady?.call();
      },
    );
  }
}
