import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/event_fade.dart';
import '../../../core/interfaces/map_engine.dart';
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
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
    final color = expired ? const Color(0xFF9E9E9E) : Color(markerColor(marker));
    final label = (expired && deadline != null)
        ? (EventFade.negativeLabel(deadline, now) ?? '')
        : '';
    final highlighted = marker.isHighlighted;
    final isPulse = marker.isPartner && !expired;

    return Marker(
      point: marker.location.toLatLng(),
      width: isPulse ? 80 : (highlighted ? 88 : 72),
      height: isPulse ? 56 : (highlighted ? 40 : 32),
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () => onTap(marker),
        child: isPulse
            ? _PulseMarkerWidget(
                key: ValueKey(marker.id),
                color: color,
                highlighted: highlighted,
                deadline: deadline,
              )
            : _MarkerPin(
                key: ValueKey(marker.id),
                color: color,
                label: label,
                highlighted: highlighted,
                deadline: deadline,
              ),
      ),
    );
  }
}

// ── 마커 핀 위젯 ──────────────────────────────────────────────────────────────

class _MarkerPin extends StatefulWidget {
  final Color color;
  final String label;
  final bool highlighted;
  final DateTime? deadline;

  const _MarkerPin({
    super.key,
    required this.color,
    required this.label,
    this.highlighted = false,
    this.deadline,
  });

  @override
  State<_MarkerPin> createState() => _MarkerPinState();
}

class _MarkerPinState extends State<_MarkerPin> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.deadline != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    final fade = deadline != null ? EventFade.opacity(deadline, _now) : 1.0;
    final pinColor = (deadline != null && EventFade.isGrayed(deadline, _now))
        ? const Color(0xFF9E9E9E)
        : widget.color;

    return Opacity(
      opacity: fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: pinColor,
              borderRadius: BorderRadius.circular(7),
              border: widget.highlighted
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: widget.highlighted ? 0.35 : 0.20),
                  blurRadius: widget.highlighted ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.label.isEmpty ? ' ' : widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
          ),
          CustomPaint(
            painter: _PinTipPainter(color: pinColor),
            size: const Size(14, 8),
          ),
        ],
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PinTipPainter old) => old.color != color;
}

// ── 파트너 이벤트 펄스 마커 ────────────────────────────────────────────────────

class _PulseMarkerWidget extends StatefulWidget {
  final Color color;
  final bool highlighted;
  final DateTime? deadline;

  const _PulseMarkerWidget({
    super.key,
    required this.color,
    this.highlighted = false,
    this.deadline,
  });

  @override
  State<_PulseMarkerWidget> createState() => _PulseMarkerWidgetState();
}

class _PulseMarkerWidgetState extends State<_PulseMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF16213E);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final now = DateTime.now();
        final deadline = widget.deadline;
        final fade = deadline != null ? EventFade.opacity(deadline, now) : 1.0;
        final isGrayed =
            deadline != null && EventFade.isGrayed(deadline, now);
        final activeColor = isGrayed
            ? const Color(0xFF9E9E9E)
            : (widget.highlighted ? selectedColor : widget.color);

        return Opacity(
          opacity: fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: (1.0 - _ctrl.value).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.5 + _ctrl.value,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: widget.highlighted ? 0.35 : 0.20),
                            blurRadius: widget.highlighted ? 6 : 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        '지금',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                painter: _PinTipPainter(color: activeColor),
                size: const Size(14, 8),
              ),
            ],
          ),
        );
      },
    );
  }
}
