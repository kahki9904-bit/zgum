import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../features/partner_room/data/repositories/partner_repository.dart';

class MockPartnerRepository implements PartnerRepository {
  final List<PartnerEventDraft> _events = [];
  final Map<String, StreamController<PaymentStatus>> _paymentStreams = {};

  @override
  Future<PartnerEventDraft> createEventDraft({
    required String title,
    required String venue,
    String? message,
    required LatLng location,
    required DateTime startsAt,
    required DateTime expiresAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final draft = PartnerEventDraft(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      venue: venue,
      message: message,
      location: location,
      startsAt: startsAt,
      expiresAt: expiresAt,
      paymentStatus: PaymentStatus.pending,
    );
    _events.add(draft);
    return draft;
  }

  @override
  Future<String> initiatePayment(String draftId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'https://mock-payment.zgum.test/pay/$draftId';
  }

  @override
  Future<PaymentStatus> fetchPaymentStatus(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return PaymentStatus.pending;
  }

  @override
  Stream<PaymentStatus> watchPaymentStatus(String orderId) {
    _paymentStreams[orderId] ??= StreamController<PaymentStatus>.broadcast();
    return _paymentStreams[orderId]!.stream;
  }

  @override
  Future<List<PartnerEventDraft>> fetchMyEvents() async => List.unmodifiable(_events);

  @override
  Future<PartnerEventStats> fetchEventStats(String eventId) async {
    return PartnerEventStats(eventId: eventId, visitCount: 0, traceCount: 0);
  }

  @override
  Future<void> cancelEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    _paymentStreams[eventId]?.close();
    _paymentStreams.remove(eventId);
  }
}
