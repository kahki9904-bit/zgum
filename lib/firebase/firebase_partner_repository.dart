// Firestore 연동 포인트: 컬렉션 'partner_events/{eventId}'
// 전환 시: server_transition_providers.dart 에서 MockPartnerRepository → FirebasePartnerRepository 교체
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../features/partner_room/data/repositories/partner_repository.dart';
import '../features/alert/models/partner_event.dart' as pe;
import '../services/firestore_partner_event_service.dart';

class FirebasePartnerRepository implements PartnerRepository {
  FirebasePartnerRepository({FirebaseAuth? auth, FirestorePartnerEventService? service})
      : _auth = auth ?? FirebaseAuth.instance,
        _service = service ?? FirestorePartnerEventService();

  final FirebaseAuth _auth;
  final FirestorePartnerEventService _service;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인 필요');
    return user.uid;
  }

  @override
  Future<PartnerEventDraft> createEventDraft({
    required String title,
    required String venue,
    String? message,
    required LatLng location,
    required DateTime startsAt,
    required DateTime expiresAt,
  }) async {
    final id = 'event_${DateTime.now().millisecondsSinceEpoch}';
    await _service.save(pe.PartnerEvent(
      id: id,
      partnerId: _uid,
      title: title,
      venue: venue,
      message: message,
      location: location,
      geoHash: '',
      startsAt: startsAt,
      expiresAt: expiresAt,
    ));
    return PartnerEventDraft(
      id: id,
      title: title,
      venue: venue,
      message: message,
      location: location,
      startsAt: startsAt,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<String> initiatePayment(String draftId) =>
      throw UnimplementedError('결제 연동 후 구현');

  @override
  Future<PaymentStatus> fetchPaymentStatus(String orderId) =>
      throw UnimplementedError('결제 연동 후 구현');

  @override
  Stream<PaymentStatus> watchPaymentStatus(String orderId) =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  Future<List<PartnerEventDraft>> fetchMyEvents() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<PartnerEventStats> fetchEventStats(String eventId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> cancelEvent(String eventId) =>
      throw UnimplementedError('Firestore 연동 후 구현');
}
