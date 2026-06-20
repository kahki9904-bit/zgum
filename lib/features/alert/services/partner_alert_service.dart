import '../models/partner_event.dart';

abstract interface class PartnerAlertService {
  /// 현재 보유한 이벤트 목록 (스트림 구독 전 초기값으로 사용)
  List<PartnerEvent> get currentEvents;

  /// 활성 파트너 이벤트 스트림 (폴링 or FCM → 동일 인터페이스)
  Stream<List<PartnerEvent>> get events;

  /// 특정 이벤트 확인 처리 (낙관적 업데이트)
  Future<void> markAsSeen(String eventId);

  /// 모든 이벤트 확인 처리
  Future<void> markAllAsSeen();

  /// 수동 새로고침
  Future<void> refresh();

  /// Timer 등 리소스 해제 — ref.onDispose에서 호출
  void dispose();
}
