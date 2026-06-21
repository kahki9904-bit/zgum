// Firestore 연동 포인트: 컬렉션 'partner_events/{eventId}'
// 전환 시: server_transition_providers.dart 에서 MockPartnerRepository → FirebasePartnerRepository 교체
import 'package:latlong2/latlong.dart';
import '../features/partner_room/data/repositories/partner_repository.dart';

class FirebasePartnerRepository implements PartnerRepository {
  @override
  Future<PartnerEventDraft> createEventDraft({
    required String title,
    required String venue,
    String? message,
    required LatLng location,
    required DateTime startsAt,
    required DateTime expiresAt,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

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
