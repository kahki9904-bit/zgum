/// 관리자가 심사·지정한 검증된 오프라인 사업장.
/// 일반 파트너(개인 이벤트 등록)와 다른 개념 — 공간 자체가 Z:GUM 생태계의 일부.
/// Firebase 연동 후 별도 컬렉션으로 관리. 앱 내 셀프 등록 없음, 운영팀 직접 지정.
class ByZGumSpace {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double lng;
  final String address;

  // Z:GIM ZONE과 달리 사업장 단위 — 반경 대신 건물/공간 포인트 기준
  const ByZGumSpace({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.address,
  });
}
