import 'map_marker_model.dart';

/// Z:GUM 앱 전체에서 사용하는 핵심 데이터 단위.
///
/// 공공데이터, 네이버, 카카오, 파트너 등 어떤 소스에서 오든
/// 이 모델 하나로 지도 마커·리스트·상세 시트를 모두 표현합니다.
///
/// ## 두 가지 레이어
/// - [deadline] 이 있으면 **Realtime** 레이어: 지도 마커 + 긴박감 연출
/// - [deadline] 이 없으면 **Information** 레이어: 카테고리/검색 리스트
class AppModel {
  final String id;

  /// 장소·이벤트 이름
  final String title;

  /// 위치
  final MapCoordinate location;

  /// 콘텐츠 유형
  final MarkerCategory category;

  /// 마감 일시. null 이면 Information 레이어.
  final DateTime? deadline;

  /// 성인 전용 여부
  final bool isAdultOnly;

  /// 파트너(소상공인) 등록 여부
  final bool isPartner;

  /// 장소명 (선택)
  final String? venue;

  /// 주소 (선택)
  final String? address;

  /// 대표 이미지 URL (선택)
  final String? imageUrl;

  /// "지금 가야 할 이유" 한 줄 설명
  final String? essentialAction;

  /// 상세 링크 또는 전화번호 (선택)
  final String? link;

  /// 원본 API 응답 객체 — Adapter 를 통해 변환 전 데이터 보존
  final Object? rawSource;

  const AppModel({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    this.deadline,
    this.isAdultOnly = false,
    this.isPartner = false,
    this.venue,
    this.address,
    this.imageUrl,
    this.essentialAction,
    this.link,
    this.rawSource,
  });

  // ── 레이어 분류 ──────────────────────────────────────────────────────────────

  bool get isRealtime => deadline != null;

  bool isExpired({DateTime? now}) {
    if (deadline == null) return false;
    return (now ?? DateTime.now()).isAfter(deadline!);
  }

  int? minutesLeft({DateTime? now}) {
    if (deadline == null) return null;
    return deadline!.difference(now ?? DateTime.now()).inMinutes;
  }

  bool get isUrgent {
    final mins = minutesLeft();
    return mins != null && mins > 0 && mins <= 60;
  }

  // ── MapMarkerModel 변환 ──────────────────────────────────────────────────────

  MapMarkerModel toMarker() => MapMarkerModel(
        id: id,
        location: location,
        category: category,
        deadline: deadline,
        isAdultOnly: isAdultOnly,
        title: title,
        venue: venue,
        isPartner: isPartner,
        payload: this,
      );
}
