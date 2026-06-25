import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/event_fade.dart';
import '../../../core/interfaces/map_engine.dart';
import '../../../core/map_marker_layout.dart';
import '../../../core/models/map_marker_model.dart';

// ── 좌표 변환 헬퍼 ─────────────────────────────────────────────────────────────

extension on MapCoordinate {
  LatLng toLatLng() => LatLng(latitude, longitude);
}

extension on LatLng {
  MapCoordinate toCoordinate() => MapCoordinate(latitude, longitude);
}

// ── 컨트롤러 ──────────────────────────────────────────────────────────────────

class _FlutterMapController implements MapEngineController {
  final MapController _ctrl;

  _FlutterMapController(this._ctrl);

  @override
  void move(MapCoordinate center, double zoom) {
    _ctrl.move(center.toLatLng(), zoom);
  }

  @override
  MapCoordinate get center => _ctrl.camera.center.toCoordinate();

  @override
  Object get raw => _ctrl;
}

// ── 엔진 ──────────────────────────────────────────────────────────────────────

class FlutterMapEngine extends MapEngine {
  @override
  MapEngineController createController() {
    return _FlutterMapController(MapController());
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
    final ctrl = (controller.raw as MapController);
    final routeLatLngs = routePoints?.map((c) => c.toLatLng()).toList();

    return FlutterMap(
      mapController: ctrl,
      options: MapOptions(
        initialCenter: initialCenter.toLatLng(),
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.zgum.app',
        ),
        if (routeLatLngs != null && routeLatLngs.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routeLatLngs,
                color: const Color(0xFF16213E),
                strokeWidth: 4.0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (userLocation != null) _buildUserMarker(userLocation),
            ...markers.map((m) => _buildMarker(m, onMarkerTap)),
          ],
        ),
      ],
    );
  }

  Marker _buildUserMarker(MapCoordinate location) {
    return Marker(
      point: location.toLatLng(),
      width: 48,
      height: 52,
      alignment: Alignment.bottomCenter,
      child: const _MapDropMarker(
        fillColor: Color(0xFFD9BD7A),
        borderColor: Color(0xFFFFFCF4),
        centerColor: Color(0xF0FFFFFF),
      ),
    );
  }

  Marker _buildMarker(
    MapMarkerModel marker,
    void Function(MapMarkerModel) onTap,
  ) {
    final now = DateTime.now();
    final deadline = marker.deadline;
    final expired = marker.isExpired(now: now);
    final color =
        expired ? const Color(0xFF9E9E9E) : Color(markerColor(marker));
    final highlighted = marker.isHighlighted;
    final shouldBlink = !expired && !marker.isDimmed;

    return Marker(
      point: marker.location.toLatLng(),
      width: MapMarkerLayoutSpec.current.bitmapSize + 8,
      height: MapMarkerLayoutSpec.current.bitmapSize + 12,
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: marker.isDimmed ? 0.22 : 1.0,
        child: GestureDetector(
          onTap: () => onTap(marker),
          child: _MarkerPin(
            key: ValueKey(marker.id),
            color: color,
            isSearch: _isSearchMarker(marker),
            highlighted: highlighted,
            deadline: deadline,
            blink: shouldBlink,
          ),
        ),
      ),
    );
  }
}

// ── 이벤트 마커 핀 ────────────────────────────────────────────────────────────

class _MarkerPin extends StatefulWidget {
  final Color color;
  final bool isSearch;
  final bool highlighted;
  final DateTime? deadline;
  final bool blink;

  const _MarkerPin({
    super.key,
    required this.color,
    this.isSearch = false,
    this.highlighted = false,
    this.deadline,
    this.blink = false,
  });

  @override
  State<_MarkerPin> createState() => _MarkerPinState();
}

class _MarkerPinState extends State<_MarkerPin>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime _now = DateTime.now();
  AnimationController? _blinkCtrl;
  Animation<double>? _blinkAnim;

  @override
  void initState() {
    super.initState();
    if (widget.deadline != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
    if (widget.blink) {
      _blinkCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true);
      _blinkAnim = Tween<double>(begin: 0.8, end: 0.35).animate(
        CurvedAnimation(parent: _blinkCtrl!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    final fade = deadline != null ? EventFade.opacity(deadline, _now) : 1.0;
    final pinColor = (deadline != null && EventFade.isGrayed(deadline, _now))
        ? const Color(0xFF9E9E9E)
        : widget.color;

    Widget pin = Opacity(
      opacity: fade,
      child: widget.isSearch
          ? _MapTargetMarker(color: pinColor)
          : _MapDropMarker(
              fillColor: pinColor,
              borderColor: const Color(0xFFFFFCF4),
              centerColor: Colors.white.withValues(
                alpha: widget.highlighted ? 0.96 : 0.9,
              ),
              highlighted: widget.highlighted,
            ),
    );

    if (widget.blink && _blinkAnim != null) {
      return AnimatedBuilder(
        animation: _blinkAnim!,
        builder: (_, child) =>
            Opacity(opacity: _blinkAnim!.value, child: child!),
        child: pin,
      );
    }
    return pin;
  }
}

bool _isSearchMarker(MapMarkerModel marker) =>
    marker.category == MarkerCategory.other ||
    marker.category == MarkerCategory.cinema;

class _MapTargetMarker extends StatelessWidget {
  const _MapTargetMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final spec = MapMarkerLayoutSpec.current;
    final outerSize = spec.pinSize * 0.84;
    final innerSize = outerSize * 0.58;
    final dotSize = spec.centerSize * 0.68;

    return Center(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: spec.borderWidth * 1.25,
          ),
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: spec.borderWidth * 0.75,
              ),
            ),
            child: Center(
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapDropMarker extends StatelessWidget {
  const _MapDropMarker({
    required this.fillColor,
    required this.centerColor,
    this.borderColor = Colors.white,
    this.highlighted = false,
  });

  final Color fillColor;
  final Color centerColor;
  final Color borderColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -0.785398,
        child: Container(
          width: highlighted
              ? MapMarkerLayoutSpec.current.highlightedPinSize
              : MapMarkerLayoutSpec.current.pinSize,
          height: highlighted
              ? MapMarkerLayoutSpec.current.highlightedPinSize
              : MapMarkerLayoutSpec.current.pinSize,
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
              width: highlighted
                  ? MapMarkerLayoutSpec.current.highlightedBorderWidth
                  : MapMarkerLayoutSpec.current.borderWidth,
            ),
            boxShadow: MapMarkerLayoutSpec.current.shadowBlur <= 0
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: highlighted ? 0.3 : 0.18,
                      ),
                      blurRadius: highlighted
                          ? MapMarkerLayoutSpec.current.highlightedShadowBlur
                          : MapMarkerLayoutSpec.current.shadowBlur,
                      offset: Offset(
                        0,
                        MapMarkerLayoutSpec.current.shadowOffsetY,
                      ),
                    ),
                  ],
          ),
          child: Center(
            child: Container(
              width: highlighted
                  ? MapMarkerLayoutSpec.current.highlightedCenterSize
                  : MapMarkerLayoutSpec.current.centerSize,
              height: highlighted
                  ? MapMarkerLayoutSpec.current.highlightedCenterSize
                  : MapMarkerLayoutSpec.current.centerSize,
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
      ),
    );
  }
}
