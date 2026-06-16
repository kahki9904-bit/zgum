import '../../core/app_config.dart';
import '../../core/models/map_marker_model.dart';

/// 네이버 지역 검색 API 저장소 스텁.
///
/// ## 연동 방법
/// 1. developers.naver.com 에서 앱 등록 → 클라이언트 ID/Secret 발급
/// 2. flutter run --dart-define=NAVER_CLIENT_ID=xxx --dart-define=NAVER_CLIENT_SECRET=xxx
/// 3. 아래 fetchNearbyPlaces() 구현 작성
///
/// 네이버 지역 검색 API 문서:
/// https://developers.naver.com/docs/serviceapi/search/local/local.md
abstract class NaverLocalRepository {
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int display = 5,
  });
}

/// 네이버 API 미연동 상태에서 사용하는 빈 구현체.
class StubNaverLocalRepository implements NaverLocalRepository {
  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int display = 5,
  }) async {
    assert(
      AppConfig.hasNaverKey,
      'NAVER_CLIENT_ID 가 설정되지 않았습니다. '
      'flutter run --dart-define=NAVER_CLIENT_ID=xxx 로 실행하세요.',
    );
    return [];
  }
}

/// 실제 네이버 지역 검색 API 구현체 (연동 시 작성).
class ApiNaverLocalRepository implements NaverLocalRepository {
  // TODO: Dio 인스턴스 + 헤더(X-Naver-Client-Id, X-Naver-Client-Secret) 설정
  // https://openapi.naver.com/v1/search/local.json
  // 파라미터: query, display, start, sort(random|comment)

  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int display = 5,
  }) {
    throw UnimplementedError('ApiNaverLocalRepository 미구현');
  }
}
