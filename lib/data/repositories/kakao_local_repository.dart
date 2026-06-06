import '../../core/app_config.dart';
import '../models/map_marker_model.dart';

/// 카카오 로컬 API 저장소 스텁.
///
/// ## 연동 방법
/// 1. developers.kakao.com 에서 앱 등록 → REST API 키 발급
/// 2. flutter run --dart-define=KAKAO_API_KEY=xxx
/// 3. 아래 fetchNearbyPlaces() 구현 작성
///
/// 카카오 로컬 API 문서:
/// https://developers.kakao.com/docs/latest/ko/local/dev-guide
abstract class KakaoLocalRepository {
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
  });
}

/// 카카오 API 미연동 상태에서 사용하는 빈 구현체.
class StubKakaoLocalRepository implements KakaoLocalRepository {
  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
  }) async {
    assert(
      AppConfig.hasKakaoKey,
      'KAKAO_API_KEY 가 설정되지 않았습니다. '
      'flutter run --dart-define=KAKAO_API_KEY=xxx 로 실행하세요.',
    );
    return [];
  }
}

/// 실제 카카오 로컬 API 구현체 (연동 시 작성).
class ApiKakaoLocalRepository implements KakaoLocalRepository {
  // TODO: Dio 인스턴스 + 헤더(Authorization: KakaoAK {REST_API_KEY}) 설정
  // https://dapi.kakao.com/v2/local/search/keyword.json
  // 파라미터: query, x(경도), y(위도), radius(미터), size, sort(distance|accuracy)

  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
  }) {
    throw UnimplementedError('ApiKakaoLocalRepository 미구현');
  }
}
