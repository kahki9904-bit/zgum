/// 지도 엔진에 독립적인 좌표 타입.
///
/// latlong2, NaverMap, KakaoMap 등 외부 패키지의 좌표 클래스를 직접 사용하는
/// 대신 이 타입을 프로젝트 내부 표준으로 사용합니다.
class MapCoordinate {
  final double latitude;
  final double longitude;

  const MapCoordinate(this.latitude, this.longitude);

  @override
  String toString() => 'MapCoordinate($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is MapCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

// ── 마커 카테고리 ──────────────────────────────────────────────────────────────

/// 지도 마커가 가질 수 있는 콘텐츠 유형.
///
/// 새 카테고리가 생기면 여기에만 추가하면 됩니다.
/// 각 MapEngine 구현체가 이 값을 읽어 색상·아이콘을 결정합니다.
enum MarkerCategory {
  movie,       // 영화
  theater,     // 연극·뮤지컬
  exhibition,  // 전시·미술
  show,        // 관람
  concert,     // 공연
  sale,        // 타임세일 (파트너)
  cinema,      // 영화관 (장소)
  partner,     // 파트너 일반
  other,       // 기타
}

// ── 마커 데이터 모델 ───────────────────────────────────────────────────────────

/// 지도 위에 표시되는 마커 하나의 순수 데이터 구조.
///
/// flutter_map, 네이버 지도, 카카오 지도 등 어떤 엔진이 사용되더라도
/// 이 모델만으로 마커를 렌더링할 수 있어야 합니다.
///
/// [payload] 에는 원본 도메인 객체(CulturalEvent 등)를 담아 두었다가
/// 마커 탭 시 상세 시트를 여는 데 사용하세요.
class MapMarkerModel {
  final String id;
  final MapCoordinate location;
  final MarkerCategory category;

  /// 마감 일시 (null = 상설/마감 없음).
  final DateTime? deadline;

  final bool isAdultOnly;
  final String title;
  final String? venue;
  final bool isPartner;
  final bool isHighlighted;

  /// 원본 도메인 객체 (CulturalEvent, CinemaModel 등).
  final Object? payload;

  const MapMarkerModel({
    required this.id,
    required this.location,
    required this.category,
    this.deadline,
    this.isAdultOnly = false,
    required this.title,
    this.venue,
    this.isPartner = false,
    this.isHighlighted = false,
    this.payload,
  });

  bool isExpired({DateTime? now}) {
    if (deadline == null) return false;
    return (now ?? DateTime.now()).isAfter(deadline!);
  }

  int? minutesLeft({DateTime? now}) {
    if (deadline == null) return null;
    return deadline!.difference(now ?? DateTime.now()).inMinutes;
  }
}
