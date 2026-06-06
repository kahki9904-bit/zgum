/// 이벤트 시간 판정 유틸리티.
///
/// 모든 함수는 [now] 파라미터로 기준 시각을 주입받아 **단위 테스트가 가능**합니다.
/// 생략 시 [DateTime.now()]를 사용합니다.
///
/// ## 설계 원칙
/// - "만료"는 요일 단위가 아닌 **분 단위** DateTime 비교로 판정합니다.
/// - [TimeService.now()]를 통한 NTP 서버 시각과 결합해 정밀도를 확보합니다.

library;

// ── 기본 판정 ─────────────────────────────────────────────────────────────────

/// [endDateTime]까지 남은 시간. 이미 지났으면 [Duration.zero].
Duration remainingDuration(DateTime endDateTime, {DateTime? now}) {
  final diff = endDateTime.difference(now ?? DateTime.now());
  return diff.isNegative ? Duration.zero : diff;
}

/// 남은 분. 이미 지났으면 0.
int minutesLeft(DateTime endDateTime, {DateTime? now}) =>
    remainingDuration(endDateTime, now: now).inMinutes;

/// 현재 시각(분 단위) 기준 즉시 만료 여부.
/// 요일 단위 판정이 아니라 `endDateTime`의 시:분:초까지 비교합니다.
bool isExpired(DateTime endDateTime, {DateTime? now}) =>
    endDateTime.isBefore(now ?? DateTime.now());

// ── 지도 표시 기준 ───────────────────────────────────────────────────────────

/// 지도에 표시할 이벤트 조건: 30분 이상 남은 이벤트.
/// (이전: 1시간 → 30분으로 세분화)
bool shouldShowOnMap(DateTime endDateTime, {DateTime? now}) =>
    remainingDuration(endDateTime, now: now) >= const Duration(minutes: 30);

// ── 애니메이션 강도 판정 ──────────────────────────────────────────────────────

/// 긴박 펄스 모드: **0분 초과 && 60분 이하** 남은 이벤트.
/// → 마커 링 파동 속도를 2배로 올리는 트리거로 사용합니다.
bool isUrgentPulse(DateTime endDateTime, {DateTime? now}) {
  final r = remainingDuration(endDateTime, now: now);
  return r > Duration.zero && r <= const Duration(minutes: 60);
}

/// 일반 펄스 범위: **60분 초과 && 3시간 이하** 남은 이벤트.
/// → 느린 속도의 기본 링 파동을 보여줍니다.
bool isNormalPulse(DateTime endDateTime, {DateTime? now}) {
  final r = remainingDuration(endDateTime, now: now);
  return r > const Duration(minutes: 60) && r <= const Duration(hours: 3);
}

// ── 번개 추천 필터 ────────────────────────────────────────────────────────────

/// 즉흥 코스 추천 적합 이벤트:
/// - 최소 **30분** 이상 남아있음 (도착할 시간 확보)
/// - **3시간 이내**에 종료 (지금 바로 즐길 수 있는 시간 범위)
bool isRecommendable(DateTime endDateTime, {DateTime? now}) {
  final r = remainingDuration(endDateTime, now: now);
  return r >= const Duration(minutes: 30) && r <= const Duration(hours: 3);
}

// ── 텍스트 포맷 ──────────────────────────────────────────────────────────────

/// 남은 시간을 사람이 읽기 좋은 형태로 포맷합니다.
///
/// 예시: `'1시간 23분 남음'`, `'45분 남음'`, `'마감됨'`
String formatRemaining(DateTime endDateTime, {DateTime? now}) {
  final r = remainingDuration(endDateTime, now: now);
  if (r == Duration.zero) return '마감됨';
  if (r.inDays >= 1) return '${r.inDays}일 후 마감';
  final h = r.inHours;
  final m = r.inMinutes % 60;
  if (h > 0 && m > 0) return '$h시간 $m분 남음';
  if (h > 0) return '$h시간 남음';
  return '$m분 남음';
}

/// 남은 시간을 짧은 형태로 포맷합니다 (마커 배지 등 좁은 공간용).
///
/// 예시: `'1h 23m'`, `'45m'`, `'종료'`
String formatRemainingShort(DateTime endDateTime, {DateTime? now}) {
  final r = remainingDuration(endDateTime, now: now);
  if (r == Duration.zero) return '종료';
  final h = r.inHours;
  final m = r.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}
