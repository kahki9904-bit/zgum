import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../data/models/cultural_event.dart';
import '../../data/repositories/api_cultural_event_repository.dart';
import '../../data/repositories/kopis_repository.dart';

/// 통합 검색 상태.
/// 향후 새 API 추가 시 여기에만 필드와 호출 추가.
class UnifiedSearchState {
  final bool isLoading;
  final bool hasSearched;
  final List<KopisSearchResult> kopisResults;
  final List<CulturalEvent> tourResults;

  const UnifiedSearchState({
    this.isLoading = false,
    this.hasSearched = false,
    this.kopisResults = const [],
    this.tourResults = const [],
  });

  UnifiedSearchState copyWith({
    bool? isLoading,
    bool? hasSearched,
    List<KopisSearchResult>? kopisResults,
    List<CulturalEvent>? tourResults,
  }) =>
      UnifiedSearchState(
        isLoading: isLoading ?? this.isLoading,
        hasSearched: hasSearched ?? this.hasSearched,
        kopisResults: kopisResults ?? this.kopisResults,
        tourResults: tourResults ?? this.tourResults,
      );

  bool get hasResults => kopisResults.isNotEmpty || tourResults.isNotEmpty;
}

/// 통합 검색 노티파이어.
/// 현재: KOPIS 공연명 + Tour API 행사명 병렬 검색.
/// 향후: Firebase·파트너 이벤트 등을 여기에 추가.
class UnifiedSearchNotifier extends StateNotifier<UnifiedSearchState> {
  final KopisRepository? _kopisRepo;
  final ApiCulturalEventRepository? _tourRepo;

  UnifiedSearchNotifier({
    required KopisRepository? kopisRepo,
    required ApiCulturalEventRepository? tourRepo,
  })  : _kopisRepo = kopisRepo,
        _tourRepo = tourRepo,
        super(const UnifiedSearchState());

  Future<void> search(String query) async {
    if (query.trim().length < 2) return;
    state = state.copyWith(isLoading: true, hasSearched: false);

    final results = await Future.wait([
      _kopisRepo?.searchByKeyword(query) ?? Future.value(<KopisSearchResult>[]),
      _tourRepo?.searchByKeyword(query) ?? Future.value(<CulturalEvent>[]),
    ]);

    if (!mounted) return;
    state = UnifiedSearchState(
      isLoading: false,
      hasSearched: true,
      kopisResults: results[0] as List<KopisSearchResult>,
      tourResults: results[1] as List<CulturalEvent>,
    );
  }

  void clear() => state = const UnifiedSearchState();
}

final unifiedSearchProvider =
    StateNotifierProvider<UnifiedSearchNotifier, UnifiedSearchState>((ref) {
  return UnifiedSearchNotifier(
    kopisRepo: AppConfig.hasKopisKey ? KopisRepository() : null,
    tourRepo: AppConfig.hasTourApiKey ? ApiCulturalEventRepository() : null,
  );
});
