import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/app_config.dart';
import '../models/map_marker_model.dart';

/// 검색 목적 구분.
/// 사용자 발견용과 파트너 등록용은 나중에 필터 기준이 달라질 수 있어 분리.
enum KakaoSearchContext {
  userDiscovery,       // 사용자가 현장에서 장소 탐색
  partnerRegistration, // 파트너가 이벤트 등록 시 장소 지정
}

/// 카카오 로컬 API 저장소 인터페이스.
abstract class KakaoLocalRepository {
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
    KakaoSearchContext context = KakaoSearchContext.userDiscovery,
  });
}

/// 카카오 API 키 없을 때 사용하는 빈 구현체.
class StubKakaoLocalRepository implements KakaoLocalRepository {
  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
    KakaoSearchContext context = KakaoSearchContext.userDiscovery,
  }) async {
    debugPrint('[KakaoLocal] STUB 모드 — 장소 검색 비활성화');
    debugPrint('[KakaoLocal]   원인: KAKAO_API_KEY dart-define 없음');
    debugPrint('[KakaoLocal]   해결1: VS Code > Z:GUM (Android) launch 설정으로 실행');
    debugPrint('[KakaoLocal]   해결2: flutter run --dart-define=KAKAO_API_KEY=<REST_API_키>');
    return [];
  }
}

/// 카카오 로컬 API 실구현체.
///
/// 호출 조건: 검색 버튼(키보드 완료) 입력 시에만 호출.
/// 캐시: 같은 검색어 + 소수점 3자리 위치 기준으로 메모리 캐시.
/// Authorization: KakaoAK {REST_API_KEY} 헤더 방식.
class ApiKakaoLocalRepository implements KakaoLocalRepository {
  final Dio _dio;

  // 메모리 캐시: key = "query|lat|lng"
  final Map<String, List<MapMarkerModel>> _cache = {};

  ApiKakaoLocalRepository({Dio? dio})
      : _dio = _buildDio(dio);

  static Dio _buildDio(Dio? override) {
    if (override != null) return override;
    const key = AppConfig.kakaoApiKey;

    if (key.isEmpty) {
      debugPrint('[KakaoLocal] !! 키 없음 — 이 코드 경로는 AppConfig.hasKakaoKey 체크로 도달 불가');
      debugPrint('[KakaoLocal]    API 키 없이 ApiKakaoLocalRepository가 생성됨 (버그)');
    } else {
      final preview = key.length >= 8
          ? '${key.substring(0, 4)}...${key.substring(key.length - 4)}'
          : '(길이 이상 — REST API 키 확인 필요)';
      final lenNote = key.length == 32 ? '32자 정상' : '${key.length}자 — REST API 키는 보통 32자';
      debugPrint('[KakaoLocal] 키 로드됨: KakaoAK $preview ($lenNote)');
      debugPrint('[KakaoLocal] Authorization 헤더 형식: KakaoAK $preview (공백 포함 여부: ${key.isNotEmpty})');
    }

    return Dio(BaseOptions(
      baseUrl: 'https://dapi.kakao.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': 'KakaoAK $key',
      },
    ))..interceptors.add(_KakaoLogInterceptor());
  }

  @override
  Future<List<MapMarkerModel>> fetchNearbyPlaces({
    required MapCoordinate center,
    required String query,
    int size = 5,
    KakaoSearchContext context = KakaoSearchContext.userDiscovery,
  }) async {
    final cacheKey =
        '$query|${center.latitude.toStringAsFixed(3)}|${center.longitude.toStringAsFixed(3)}';
    if (_cache.containsKey(cacheKey)) {
      debugPrint('[KakaoLocal] 캐시 히트: "$query"');
      return _cache[cacheKey]!;
    }

    debugPrint('[KakaoLocal] 검색 요청: "$query" @ ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}');

    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/local/search/keyword.json',
      queryParameters: {
        'query': query,
        'size': size.clamp(1, 5),
        'sort': 'accuracy',
      },
    );

    final documents =
        (response.data?['documents'] as List? ?? []).cast<Map<String, dynamic>>();

    final results = documents.map((doc) {
      return MapMarkerModel(
        id: doc['id']?.toString() ?? '',
        location: MapCoordinate(
          double.tryParse(doc['y']?.toString() ?? '') ?? center.latitude,
          double.tryParse(doc['x']?.toString() ?? '') ?? center.longitude,
        ),
        category: MarkerCategory.other,
        title: doc['place_name']?.toString() ?? '',
        venue: doc['address_name']?.toString(),
        roadAddress: doc['road_address_name']?.toString(),
        categoryName: doc['category_name']?.toString(),
        phone: doc['phone']?.toString(),
        placeUrl: doc['place_url']?.toString(),
        distance: doc['distance']?.toString(),
      );
    }).toList();

    if (results.isEmpty) {
      debugPrint('[KakaoLocal] 결과 없음: "$query" — 검색어 또는 위치 반경 확인');
    } else {
      debugPrint('[KakaoLocal] 결과 ${results.length}건: "$query"');
    }

    _cache[cacheKey] = results;
    return results;
  }
}

class _KakaoLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final auth = options.headers['Authorization'] as String? ?? '';
    final authPreview = auth.length > 14
        ? '${auth.substring(0, 11)}...${auth.substring(auth.length - 4)}'
        : auth;
    debugPrint('[KakaoLocal] -> ${options.baseUrl}${options.path}');
    debugPrint('[KakaoLocal]    Authorization: $authPreview');
    debugPrint('[KakaoLocal]    형식 정상 여부: ${auth.startsWith('KakaoAK ') && auth.length > 8}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;
    if (code == 401) {
      debugPrint('[KakaoLocal] !! 401 Unauthorized — 가능한 원인:');
      debugPrint('[KakaoLocal]    1) --dart-define 없이 실행 (키 빈 문자열)');
      debugPrint('[KakaoLocal]       → VS Code > Z:GUM (Android) launch 설정 사용할 것');
      debugPrint('[KakaoLocal]    2) JavaScript 키 사용 (REST API 키여야 함)');
      debugPrint('[KakaoLocal]       → developers.kakao.com > 앱 > 앱 키 > REST API 키');
      debugPrint('[KakaoLocal]    3) 카카오 로컬 API 미활성화');
      debugPrint('[KakaoLocal]       → 개발자 콘솔 > 카카오 로컬 활성화 확인');
      debugPrint('[KakaoLocal]    4) 키 만료 또는 앱 삭제됨');
    } else {
      debugPrint('[KakaoLocal] !! 오류 ${code ?? err.type.name}: ${err.message}');
    }
    handler.next(err);
  }
}

class KakaoLocalApiException implements Exception {
  final String message;
  const KakaoLocalApiException(this.message);
  @override
  String toString() => 'KakaoLocalApiException: $message';
}
