/// Z:GUM 핵심 데이터 단위.
///
/// [targetTime] 하나로 레이어를 자동 분류합니다.
///   null     → Layer.Information (발견 탭 — 카테고리/검색 목록)
///   non-null → Layer.Realtime    (지금 탭 — 지도 마커, 펄스 애니메이션)
class SpaceModel {
  final String id;

  /// 장소/이벤트 이름 (화면 표시용)
  final String title;

  /// 위도
  final double lat;

  /// 경도
  final double lng;

  /// 대표 이미지 URL (없으면 빈 문자열)
  final String thumbImage;

  /// "지금 가야 할 이유" 한 줄 설명
  /// 예: "오늘 18:00 마감 · 무료", "25분 후 시작", "타임딜 진행 중"
  final String essentialAction;

  /// 상세 페이지 URL 또는 전화번호
  final String link;

  /// 등록 주체 ID. 공공데이터: 'system', 파트너: 파트너 UID
  final String ownerId;

  /// 마감/시작 시각.
  ///   null     → Layer.Information (시간 정보 없음)
  ///   non-null → Layer.Realtime    (시간 기반 실시간 노출)
  final DateTime? targetTime;

  /// 업종 분류 (SpaceCategories 상수 사용 권장)
  final String category;

  const SpaceModel({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    this.thumbImage = '',
    required this.essentialAction,
    this.link = '',
    this.ownerId = 'system',
    this.targetTime,
    required this.category,
  });

  // ── 레이어 분류 ─────────────────────────────────────────────────────────────

  /// targetTime이 있으면 실시간 레이어, 없으면 일반 레이어.
  bool get isRealtime => targetTime != null;

  // ── 시간 계산 (targetTime이 null이면 사용 불가) ────────────────────────────

  /// 마감까지 남은 분. targetTime이 null이면 -1 반환.
  int get minutesLeft {
    if (targetTime == null) return -1;
    return targetTime!.difference(DateTime.now()).inMinutes;
  }

  /// 마감됐는지 여부 (남은 시간 0 이하).
  bool get isExpired => isRealtime && minutesLeft <= 0;

  /// 60분 이내 마감 — 긴박 펄스(빠른 링) 조건.
  bool get isUrgent => isRealtime && minutesLeft > 0 && minutesLeft <= 60;
}

// ── 카테고리 상수 ─────────────────────────────────────────────────────────────

/// [SpaceModel.category]에 사용하는 문자열 상수 모음.
abstract final class SpaceCategories {
  static const String movie    = '영화';
  static const String culture  = '문화';
  static const String food     = '미식';
  static const String cafe     = '카페';
  static const String shopping = '쇼핑';
  static const String sport    = '스포츠';
  static const String partner  = '파트너';
  static const String etc      = '기타';
}

// ── 카테고리 스타일 매핑 ──────────────────────────────────────────────────────

/// 카테고리 문자열 → UI 표현(이모지, 색상)을 반환하는 유틸리티.
///
/// 색상은 Flutter 의존 없이 ARGB int로 저장합니다.
/// UI에서: Color(SpaceCategoryStyle.colorOf('영화'))
abstract final class SpaceCategoryStyle {
  static const _table = <String, ({String emoji, int color})>{
    SpaceCategories.movie:    (emoji: '🎬', color: 0xFF1565C0),
    SpaceCategories.culture:  (emoji: '🎭', color: 0xFF9C27B0),
    SpaceCategories.food:     (emoji: '🍽️', color: 0xFFE67E22),
    SpaceCategories.cafe:     (emoji: '☕',  color: 0xFF795548),
    SpaceCategories.shopping: (emoji: '🛍️', color: 0xFFFF8C00),
    SpaceCategories.sport:    (emoji: '⚽',  color: 0xFF4CAF50),
    SpaceCategories.partner:  (emoji: '🔥',  color: 0xFFFF5722),
    SpaceCategories.etc:      (emoji: '📍',  color: 0xFF607D8B),
  };

  static String emojiOf(String category) =>
      _table[category]?.emoji ?? '📍';

  /// ARGB int — UI에서 Color(SpaceCategoryStyle.colorOf(cat)) 로 사용
  static int colorOf(String category) =>
      _table[category]?.color ?? 0xFF607D8B;
}
