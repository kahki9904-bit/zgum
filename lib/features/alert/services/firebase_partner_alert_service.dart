import 'dart:async';
import '../models/partner_event.dart';
import 'partner_alert_service.dart';
import '../../../services/firestore_partner_event_service.dart';

class FirebasePartnerAlertService implements PartnerAlertService {
  final FirestorePartnerEventService _firestoreService;
  final _controller = StreamController<List<PartnerEvent>>.broadcast();
  final _seenIds = <String>{};
  List<PartnerEvent> _current = [];
  StreamSubscription<List<PartnerEvent>>? _sub;

  FirebasePartnerAlertService({FirestorePartnerEventService? service})
      : _firestoreService = service ?? FirestorePartnerEventService() {
    _sub = _firestoreService.watchActive().listen((events) {
      _current = events
          .map((e) => e.copyWith(seen: _seenIds.contains(e.id)))
          .toList();
      _controller.add(_current);
    });
  }

  @override
  List<PartnerEvent> get currentEvents => List.unmodifiable(_current);

  @override
  Stream<List<PartnerEvent>> get events => _controller.stream;

  @override
  Future<void> markAsSeen(String eventId) async {
    _seenIds.add(eventId);
    _current = _current
        .map((e) => e.id == eventId ? e.copyWith(seen: true) : e)
        .toList();
    _controller.add(_current);
  }

  @override
  Future<void> markAllAsSeen() async {
    for (final e in _current) {
      _seenIds.add(e.id);
    }
    _current = _current.map((e) => e.copyWith(seen: true)).toList();
    _controller.add(_current);
  }

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
