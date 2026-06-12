enum EventStatusFlag {
  underReview,      // 검수중 — 등록 후 관리자 확인 대기
  active,           // 활성 — 정상 노출
  exposureLimited,  // 노출 제한 — 지도에 표시되나 검색 제외
  forceStopped,     // 강제 중단 — 관리자 즉각 비노출
  rejected,         // 반려 — 등록 거부
  expired,          // 만료 — 시스템 자동 전환 (수동 설정 불가)
  hidden,           // 숨김 — 파트너가 직접 비공개 처리
  needsAdminReview, // 관리자 확인 필요 — 이상 감지 시 플래그
}

extension EventStatusFlagX on EventStatusFlag {
  bool get isSystemManaged => this == EventStatusFlag.expired;
  bool get isVisible => this == EventStatusFlag.active || this == EventStatusFlag.exposureLimited;

  String get label => switch (this) {
        EventStatusFlag.underReview => '검수중',
        EventStatusFlag.active => '활성',
        EventStatusFlag.exposureLimited => '노출 제한',
        EventStatusFlag.forceStopped => '강제 중단',
        EventStatusFlag.rejected => '반려',
        EventStatusFlag.expired => '만료',
        EventStatusFlag.hidden => '숨김',
        EventStatusFlag.needsAdminReview => '관리자 확인 필요',
      };

  String toJson() => name;

  static EventStatusFlag fromJson(String value) =>
      EventStatusFlag.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EventStatusFlag.needsAdminReview,
      );
}
