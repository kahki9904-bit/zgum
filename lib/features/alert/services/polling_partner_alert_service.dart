import 'dart:async';
import '../models/partner_event.dart';
import 'partner_alert_service.dart';

/// Firebase 연동 전 폴링 구현체.
/// 실서버 준비 후: FirebasePartnerAlertService로 한 줄 교체.
class PollingPartnerAlertService implements PartnerAlertService {
  final Duration interval;
  final _controller = StreamController<List<PartnerEvent>>.broadcast();
  List<PartnerEvent> _current = [];
  Timer? _timer;

  PollingPartnerAlertService({
    this.interval = const Duration(seconds: 30),
  }) {
    _startPolling();
  }

  void _startPolling() {
    _poll();
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  Future<void> _poll() async {
    // TODO: 실서버 API 연동 시 http 호출 추가
    // final response = await http.get(Uri.parse('$baseUrl/partner-alerts?lat=...'));
    // _current = parseResponse(response);
    _controller.add(_current);
  }

  @override
  List<PartnerEvent> get currentEvents => List.unmodifiable(_current);

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
    await _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
