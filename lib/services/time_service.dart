import '../core/time_utils.dart' as tu;

/// 시간 계산 서비스.
///
/// [now]가 서버 시각 API 연동 진입점입니다.
/// 판정 로직은 모두 [time_utils.dart]의 순수 함수에 위임합니다.
class TimeService {
  const TimeService();

  /// 현재 시각 — NTP / 서버 시각 API로 교체할 때 이 메서드만 바꾸세요.
  DateTime now() => DateTime.now();

  /// 지도 표시 여부: **30분 이상** 남은 이벤트만 표시합니다.
  /// (이전 1시간 기준에서 30분으로 세분화 — 임박 이벤트도 표시)
  bool shouldShowEvent(DateTime endDateTime) =>
      tu.shouldShowOnMap(endDateTime, now: now());

  /// 즉시 만료 여부 (분 단위 DateTime 비교, 요일 단위 아님)
  bool isExpired(DateTime endDateTime) => tu.isExpired(endDateTime, now: now());

  /// 긴박 펄스 모드 여부: 0분 초과 && 60분 이하 남음
  bool isUrgentPulse(DateTime endDateTime) =>
      tu.isUrgentPulse(endDateTime, now: now());

  /// 일반 펄스 범위: 60분 초과 && 3시간 이하 남음
  bool isNormalPulse(DateTime endDateTime) =>
      tu.isNormalPulse(endDateTime, now: now());

  /// 번개 추천 적합 여부: 30분 이상 && 3시간 이내 종료
  bool isRecommendable(DateTime endDateTime) =>
      tu.isRecommendable(endDateTime, now: now());

  /// 남은 시간 레이블 (긴 형태)
  String remainingLabel(DateTime endDateTime) =>
      tu.formatRemaining(endDateTime, now: now());

  /// 남은 시간 레이블 (짧은 형태 — 마커 배지 등)
  String remainingLabelShort(DateTime endDateTime) =>
      tu.formatRemainingShort(endDateTime, now: now());

  /// 종료 3시간 미만 여부 (기존 isEndingSoon 동등)
  bool isEndingSoon(DateTime endDateTime) =>
      tu.isNormalPulse(endDateTime, now: now()) ||
      tu.isUrgentPulse(endDateTime, now: now());
}
