import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../../../core/models/map_marker_model.dart';
import '../../../data/repositories/kakao_local_repository.dart';

class KakaoSearchState {
  final bool isLoading;
  final bool hasSearched;
  final List<MapMarkerModel> results;
  final String? error;

  const KakaoSearchState({
    this.isLoading = false,
    this.hasSearched = false,
    this.results = const [],
    this.error,
  });

  KakaoSearchState copyWith({
    bool? isLoading,
    bool? hasSearched,
    List<MapMarkerModel>? results,
    String? error,
  }) =>
      KakaoSearchState(
        isLoading: isLoading ?? this.isLoading,
        hasSearched: hasSearched ?? this.hasSearched,
        results: results ?? this.results,
        error: error,
      );
}

class KakaoSearchNotifier extends StateNotifier<KakaoSearchState> {
  final KakaoLocalRepository _repo;

  KakaoSearchNotifier(this._repo) : super(const KakaoSearchState());

  Future<void> search({
    required String query,
    required MapCoordinate center,
    KakaoSearchContext context = KakaoSearchContext.userDiscovery,
  }) async {
    if (query.trim().isEmpty) {
      state = const KakaoSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _repo.fetchNearbyPlaces(
        center: center,
        query: query.trim(),
        size: 5,
        context: context,
      );
      state = KakaoSearchState(results: results, isLoading: false, hasSearched: true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 상세 원인 로그는 _KakaoLogInterceptor.onError 에서 출력됨
      final msg = code == 401 ? '장소를 검색할 수 없습니다' : '검색 오류 ($code)';
      state = KakaoSearchState(hasSearched: true, error: msg);
    } catch (e) {
      state = const KakaoSearchState(hasSearched: true, error: '검색 중 오류가 발생했습니다');
    }
  }

  void clear() => state = const KakaoSearchState();
}

final kakaoSearchProvider =
    StateNotifierProvider<KakaoSearchNotifier, KakaoSearchState>((ref) {
  final repo = AppConfig.hasKakaoKey
      ? ApiKakaoLocalRepository()
      : StubKakaoLocalRepository();
  return KakaoSearchNotifier(repo);
});
