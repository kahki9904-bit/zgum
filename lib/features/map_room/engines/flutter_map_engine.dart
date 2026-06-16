import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/event_fade.dart';
import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';
import '../../../presentation/widgets/icons/zgum_icon.dart';

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
      child: const _UserMarkerPin(),
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
    final shouldBlink = !expired && !marker.isDimmed;

    return Marker(
      point: marker.location.toLatLng(),
      width: highlighted ? 88 : 72,
      height: highlighted ? 40 : 36,
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: marker.isDimmed ? 0.22 : 1.0,
        child: GestureDetector(
          onTap: () => onTap(marker),
          child: _MarkerPin(
            key: ValueKey(marker.id),
            color: color,
            label: label,
            highlighted: highlighted,
            deadline: deadline,
            blink: shouldBlink,
          ),
        ),
      ),
    );
  }
}

// ── 내 위치 마커 ──────────────────────────────────────────────────────────────

class _UserMarkerPin extends StatelessWidget {
  const _UserMarkerPin();

  @override
  Widget build(BuildContext context) {
    const pinColor = Color(0xFF1A1A2E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: ZGumIcon(size: 22, color: Colors.white),
          ),
        ),
        const CustomPaint(
          painter: _PinTipPainter(color: pinColor),
          size: Size(14, 8),
        ),
      ],
    );
  }
}

// ── 이벤트 마커 핀 ────────────────────────────────────────────────────────────

class _MarkerPin extends StatefulWidget {
  final Color color;
  final String label;
  final bool highlighted;
  final DateTime? deadline;
  final bool blink;

  const _MarkerPin({
    super.key,
    required this.color,
    required this.label,
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
                height: 1.2,
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

    if (widget.blink && _blinkAnim != null) {
      return AnimatedBuilder(
        animation: _blinkAnim!,
        builder: (_, child) => Opacity(opacity: _blinkAnim!.value, child: child!),
        child: pin,
      );
    }
    return pin;
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
