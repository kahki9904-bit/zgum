import 'package:latlong2/latlong.dart';

enum PaymentStatus { pending, paid, failed, refunded }

class PartnerEventDraft {
  final String id;
  final String title;
  final String venue;
  final String? message;
  final LatLng location;
  final DateTime startsAt;
  final DateTime expiresAt;
  final PaymentStatus paymentStatus;

  const PartnerEventDraft({
    required this.id,
    required this.title,
    required this.venue,
    this.message,
    required this.location,
    required this.startsAt,
    required this.expiresAt,
    this.paymentStatus = PaymentStatus.pending,
  });
}

class PartnerEventStats {
  final String eventId;
  final int visitCount;
  final int traceCount;

  const PartnerEventStats({
    required this.eventId,
    required this.visitCount,
    required this.traceCount,
  });
}

/// 파트너가 이벤트를 등록하고 결제·통계를 관리하는 창구.
///
/// 현재: [MockPartnerRepository]
/// 추후: ApiPartnerRepository (REST + 결제사 웹훅 기반)
///
/// 중요: 앱은 PaymentStatus.paid를 직접 결정하지 않음.
///       서버가 결제사 웹훅으로 확인 후 paid 상태를 내려줌.
///       앱은 [fetchPaymentStatus] / [watchPaymentStatus]로 결과만 조회.
abstract class PartnerRepository {
  // 이벤트 초안 생성 (결제 전 단계)
  Future<PartnerEventDraft> createEventDraft({
    required String title,
    required String venue,
    String? message,
    required LatLng location,
    required DateTime startsAt,
    required DateTime expiresAt,
  });

  // 결제 시작 → 결제사 URL 반환 (앱은 WebView로 열기만 함)
  Future<String> initiatePayment(String draftId);

  // 결제 결과 1회 조회 (앱 재진입 시 보조 조회)
  Future<PaymentStatus> fetchPaymentStatus(String orderId);

  // 결제 결과 실시간 수신 (FCM push 연결 시 활성화)
  Stream<PaymentStatus> watchPaymentStatus(String orderId);

  // 내 이벤트 목록
  Future<List<PartnerEventDraft>> fetchMyEvents();

  // 이벤트 방문/흔적 통계
  Future<PartnerEventStats> fetchEventStats(String eventId);

  // 이벤트 취소/만료
  Future<void> cancelEvent(String eventId);
}
