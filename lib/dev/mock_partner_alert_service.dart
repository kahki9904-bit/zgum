import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../features/alert/models/partner_event.dart';
import '../features/alert/services/partner_alert_service.dart';

class MockPartnerAlertService implements PartnerAlertService {
  final _controller = StreamController<List<PartnerEvent>>.broadcast();
  List<PartnerEvent> _current = [];

  MockPartnerAlertService() {
    _loadMock();
  }

  void _loadMock() {
    final now = DateTime.now();
    _current = [
      PartnerEvent(
        id: 'mock-alert-001',
        partnerId: 'mock-device-001',
        title: '오늘 한정 할인 진행 중',
        venue: '홍대 카페 VIBE',
        message: '지금 방문하시면 혜택 드립니다',
        location: const LatLng(37.5519, 126.9245),
        geoHash: 'wydjx',
        startsAt: now,
        expiresAt: now.add(const Duration(minutes: 45)),
      ),
    ];
    _controller.add(_current);
  }

  @override
  Stream<List<PartnerEvent>> get events => _controller.stream;

  @override
  Future<void> markAsSeen(String eventId) async {
    _current = _current
        .map((e) => e.id == eventId ? e.copyWith(seen: true) : e)
        .toList();
    _controller.add(_current);
  }

  @override
  Future<void> markAllAsSeen() async {
    _current = _current.map((e) => e.copyWith(seen: true)).toList();
    _controller.add(_current);
  }

  @override
  Future<void> refresh() async {
    _loadMock();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
