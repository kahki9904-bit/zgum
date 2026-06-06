// 1. 모델 정의
class SpaceModel {
  final String name;      // 장소 이름
  final String type;      // 유형 (영화, 카페, 맛집 등)
  final bool hasTimeInfo; // 시간 정보 여부

  SpaceModel(this.name, this.type, this.hasTimeInfo);
}

// 2. 실행 시작점
void main() {
  print("--- Z:GUM 1차 테스트를 시작합니다 ---");

  // 샘플 데이터 생성
  List<SpaceModel> dataList = [
    SpaceModel("영화관", "영화", true),
    SpaceModel("카페", "카페", true),
    SpaceModel("맛집", "음식점", false),
  ];

  // 분류 로직 (Realtime vs Information)
  print("\n[Realtime Layer - 실시간 데이터]");
  dataList.where((s) => s.hasTimeInfo).forEach((s) {
    print("- ${s.name} (${s.type})");
  });

  print("\n[Information Layer - 일반 데이터]");
  dataList.where((s) => !s.hasTimeInfo).forEach((s) {
    print("- ${s.name} (${s.type})");
  });

  print("\n--- 테스트 완료 ---");
}