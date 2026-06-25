import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants.dart';
import '../../../core/event_fade.dart';
import '../../../core/geo_utils.dart';
import '../../../core/interfaces/map_engine.dart';
import '../../../core/providers/user_location_provider.dart';
import '../../../core/models/map_marker_model.dart';
import '../../../data/adapters/cultural_event_adapter.dart';
import '../../../core/shell_gesture_layout.dart';
import '../../../core/providers/partner_focus_provider.dart';
import '../../../data/models/cultural_event.dart';
import '../../../core/app_config.dart';
import '../../../data/repositories/api_cultural_event_repository.dart';
import '../../../data/repositories/cultural_event_repository.dart';
import '../../../data/repositories/kopis_repository.dart';
import '../../../dev/mock_cultural_event_repository.dart';
import '../../../services/firestore_partner_event_service.dart';
import '../../alert/models/partner_event.dart';
import '../../../data/repositories/sdsc_store_repository.dart';
import '../../../services/location_service.dart';
import '../../../services/time_service.dart';
import '../../../presentation/widgets/sheets/event_detail_sheet.dart';
import '../../../presentation/widgets/sheets/kakao_place_detail_sheet.dart';
import '../../../data/models/check_in_record.dart';
import '../../user_room/providers/auth_provider.dart';
import '../../user_room/providers/check_in_provider.dart';
import '../engines/google_map_engine.dart';
import '../providers/map_filter_provider.dart';
import '../providers/kakao_search_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../core/providers/active_partner_event_provider.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../../core/providers/unified_search_provider.dart';
import '../../../core/theme/app_colors.dart';

class MapRoomScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwipeToUserRoom;
  final VoidCallback? onSwipeToPartnerRoom;
  final VoidCallback? onMapReady;

  const MapRoomScreen({
    super.key,
    this.onSwipeToUserRoom,
    this.onSwipeToPartnerRoom,
    this.onMapReady,
  });

  @override
  ConsumerState<MapRoomScreen> createState() => MapRoomScreenState();
}

class MapRoomScreenState extends ConsumerState<MapRoomScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final AnimationController _pulseController;
  final bool _partnerEventSeen = false;

  // ── 지도 엔진 (여기만 바꾸면 지도 교체 완료) ─────────────────────────────────
  final MapEngine _engine = GoogleMapEngine();

  final _locationService = LocationService();
  final CulturalEventRepository _publicRepo = AppConfig.hasTourApiKey
      ? ApiCulturalEventRepository()
      : MockCulturalEventRepository();
  final CulturalEventRepository? _kopisRepo =
      AppConfig.hasKopisKey ? KopisRepository() : null;
  final CulturalEventRepository? _partnerRepo =
      AppConfig.hasSdscKey ? SdscStoreRepository() : null;
  final _timeService = const TimeService();

  late final MapEngineController _mapCtrl;

  LatLng _center = AppConstants.defaultLocation;
  MapCoordinate get _centerCoord =>
      MapCoordinate(_center.latitude, _center.longitude);

  List<CulturalEvent> _events = [];
  Map<String, CulturalEvent> _eventById = {};
  List<MapMarkerModel> _markers = [];

  // ── 이벤트별 만료 타이머 (4번: 즉시 삭제) ────────────────────────────────────
  final Map<String, Timer> _eventTimers = {};

  // ── 공공 API 호출 간격 제한 ──────────────────────────────────────────────────
  // TODO: 파트너 확보 후 간격 조정 (예: Duration(minutes: 5))
  // showPublicApiMarkers = false 전환 시 함께 설정
  static const _minPublicApiFetchInterval = Duration(minutes: 0); // 0 = 제한 없음
  DateTime? _lastPublicApiFetch;

  // ── 검색 ──────────────────────────────────────────────────────────────────
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  String? _highlightedEventId;
  Timer? _searchDebounce;

  // ── 카카오 장소 핀 ────────────────────────────────────────────────────────────
  MapCoordinate? _searchFocusCoord;
  String? _searchFocusName;
  MapMarkerModel? _searchFocusPlace;
  static const _searchPinId = '__kakao_search_pin__';
  // ── GPS 상태 ───────────────────────────────────────────────────────────────
  bool _locationAcquiring = true;
  bool _needsManualLocation = false;

  // ── 체크인 (checkInProvider에서 관리) ────────────────────────────────────

  // ── 경로 안내 ──────────────────────────────────────────────────────────────
  List<MapCoordinate> _routeCoords = [];
  bool _isNavigating = false;
  bool _isLoadingRoute = false;

  // 파트너 이벤트 포커스: 지도 이동 후 팝업 표시까지 대기 시간 (조정 가능)

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _mapCtrl = _engine.createController();
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final t in _eventTimers.values) {
      t.cancel();
    }
    _eventTimers.clear();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get isNavigating => _isNavigating;

  void recenterOnUser() {
    if (!mounted || _locationAcquiring) return;
    _stopNavigation();
    setState(() {
      _highlightedEventId = null;
      _searchFocusCoord = null;
      _searchFocusName = null;
      _searchFocusPlace = null;
      _searchOpen = false;
    });
    _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);
    _rebuildMarkers();
  }

  void _focusPartnerEvent(CulturalEvent event) {
    if (!mounted) return;
    _stopNavigation();
    _mapCtrl.move(
      MapCoordinate(event.location.latitude, event.location.longitude),
      AppConstants.defaultZoom,
    );
    setState(() {
      _highlightedEventId = event.id;
      _searchFocusCoord = null;
      _searchFocusName = null;
      _searchFocusPlace = null;
      _searchOpen = false;
    });
    _rebuildMarkers();
    ref.read(partnerFocusProvider.notifier).state = null;
    ref.read(partnerFocusPendingProvider.notifier).state = false;
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (!mounted) return;
      await _showEventSheet(event);
      if (mounted) _rebuildMarkers();
    });
  }

  Future<void> _init() async {
    final result = await _locationService.acquireLocation();
    if (!mounted) return;
    setState(() {
      _center = result.position;
      _locationAcquiring = false;
      _needsManualLocation = result.needsManual;
    });
    // 전역 위치 Provider 갱신 → GeofenceProvider가 정확한 위치로 비교
    ref.read(userLocationProvider.notifier).state = result.position;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);
    });
    if (!result.needsManual) await _loadEvents();
  }

  void _confirmManualLocation() {
    setState(() => _needsManualLocation = false);
    _locationService.saveLastKnown(_center);
    ref.read(userLocationProvider.notifier).state = _center;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    final isIdentityVerified = ref.read(authStateProvider).isIdentityVerified;

    // 공공 API 호출 간격 체크 — _minPublicApiFetchInterval 조정으로 제한
    final fetchTime = DateTime.now();
    final canFetchPublic = _minPublicApiFetchInterval == Duration.zero ||
        _lastPublicApiFetch == null ||
        fetchTime.difference(_lastPublicApiFetch!) >=
            _minPublicApiFetchInterval;
    if (canFetchPublic) _lastPublicApiFetch = fetchTime;

    // public / partner 를 각각 독립적으로 호출 — 한 쪽 실패가 다른 쪽을 막지 않음
    List<CulturalEvent> publicEvents = [];
    if (canFetchPublic) {
      try {
        publicEvents = await _publicRepo.fetchNearbyEvents(
          center: _center,
          radiusKm: AppConstants.defaultRadiusKm,
          isIdentityVerified: isIdentityVerified,
        );
      } catch (e, st) {
        debugPrint('[MapRoom] public API 실패 — 빈 목록으로 계속: $e');
        debugPrintStack(label: '[MapRoom] public stack', stackTrace: st);
      }
    }

    List<CulturalEvent> kopisEvents = [];
    if (_kopisRepo != null) {
      try {
        kopisEvents = await _kopisRepo.fetchNearbyEvents(
          center: _center,
          radiusKm: AppConstants.defaultRadiusKm,
          isIdentityVerified: isIdentityVerified,
        );
      } catch (e, st) {
        debugPrint('[MapRoom] KOPIS API 실패 — 빈 목록으로 계속: $e');
        debugPrintStack(label: '[MapRoom] KOPIS stack', stackTrace: st);
      }
    }

    List<CulturalEvent> partnerEvents = [];
    if (_partnerRepo != null) {
      try {
        partnerEvents = await _partnerRepo.fetchNearbyEvents(
          center: _center,
          radiusKm: AppConstants.defaultRadiusKm,
          isIdentityVerified: isIdentityVerified,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    final firestorePartnerEvents =
        ref.read(activePartnerEventsStreamProvider).valueOrNull ?? [];
    final partnerFromFirestore = firestorePartnerEvents
        .map((PartnerEvent e) => CulturalEvent(
              id: e.id,
              title: e.title,
              venue: e.venue,
              address: '현재 위치',
              description: e.message ?? '',
              startDate: e.startsAt,
              endDateTime: e.expiresAt,
              location: e.location,
              category: EventCategory.partner,
              isFree: false,
              source: EventSource.partner,
              partnerMessage: e.title,
              isAdultOnly: e.isAdultOnly,
            ))
        .toList();
    final all = [
      if (AppConstants.showPublicApiMarkers) ...publicEvents,
      if (AppConstants.showPublicApiMarkers) ...kopisEvents,
      ...partnerEvents,
      ...partnerFromFirestore,
    ];
    final now = _timeService.now();
    final active = all
        .where((e) => !EventFade.isFullyExpired(e.endDateTime, now))
        .toList();

    setState(() {
      _events = active;
      _eventById = {for (final e in active) e.id: e};
    });
    ref.read(mapEventsProvider.notifier).state = active;
    _scheduleEventTimers(active);
    _rebuildMarkers();
    _updatePartnerPulse();
  }

  // ── 이벤트별 정확한 만료 타이머 ────────────────────────────────────────────

  void _scheduleEventTimers(List<CulturalEvent> events) {
    for (final t in _eventTimers.values) {
      t.cancel();
    }
    _eventTimers.clear();

    final now = _timeService.now();
    for (final event in events) {
      // 종료 후 1시간이 지나면 완전 소멸
      final expiryTime = event.endDateTime.add(const Duration(hours: 1));
      final delay = expiryTime.difference(now);
      if (delay <= Duration.zero) continue;
      _eventTimers[event.id] = Timer(delay, () => _expireEventNow(event.id));
    }
  }

  void _expireEventNow(String eventId) {
    if (!mounted) return;
    setState(() {
      _events.removeWhere((e) => e.id == eventId);
      _eventById.remove(eventId);
      _eventTimers.remove(eventId);
    });
    _rebuildMarkers();
  }

  // 강조 표시 도보 반경 (분). 이 안 = 일반 마커, 밖 = 흐린 마커.
  // 데이터 호출 반경(20km)과 별개 개념.
  static const _displayRadiusMinutes = 10;

  // ── 표시 이벤트 필터링 ──────────────────────────────────────────────────────

  List<CulturalEvent> _visibleEvents(MapFilterState filter) {
    // 거리 하드 컷오프 제거: 호출된 이벤트 전부 표시 (카테고리·검색 필터만 적용)
    // 거리 기반 강조/흐림은 _rebuildMarkers 에서 isDimmed 로 처리
    return _events.where((e) => filter.passes(e)).toList();
  }

  void _rebuildMarkers() {
    if (!mounted) return;
    final filter = ref.read(mapFilterProvider);
    final visible = _visibleEvents(filter);
    final focusCoord = _searchFocusCoord;
    final checkedInIds = ref.read(checkInProvider.notifier).checkedInEventIds;

    MapMarkerModel applyState(MapMarkerModel m, {required bool dimmed}) {
      final isHL = m.id == _highlightedEventId;
      final isCI = checkedInIds.contains(m.id);
      return MapMarkerModel(
        id: m.id,
        location: m.location,
        category: m.category,
        deadline: m.deadline,
        isAdultOnly: m.isAdultOnly,
        title: m.title,
        venue: m.venue,
        isPartner: m.isPartner,
        isHighlighted: isHL || isCI,
        isDimmed: dimmed && !isHL && !isCI,
        payload: m.payload,
      );
    }

    List<MapMarkerModel> markers;

    if (focusCoord != null) {
      // 포커스 모드: 검색 핀 + 반경 안 강조, 밖 흐림
      final focusLatLng = LatLng(focusCoord.latitude, focusCoord.longitude);
      markers = [
        MapMarkerModel(
          id: _searchPinId,
          location: focusCoord,
          category: MarkerCategory.other,
          title: _searchFocusName ?? '',
          isHighlighted: true,
        ),
        ...CulturalEventAdapter.toMarkers(visible).map((m) {
          final event = _eventById[m.id];
          final mins =
              event != null ? walkingMinutes(focusLatLng, event.location) : 999;
          return applyState(m, dimmed: mins > _displayRadiusMinutes);
        }),
      ];
    } else {
      // 일반 모드: 현재 위치 기준 반경 안 강조, 밖 흐림
      markers = CulturalEventAdapter.toMarkers(visible).map((m) {
        final event = _eventById[m.id];
        final mins =
            event != null ? walkingMinutes(_center, event.location) : 999;
        return applyState(m, dimmed: mins > _displayRadiusMinutes);
      }).toList();
    }

    setState(() => _markers = markers);
  }

  void _selectKakaoPlace(MapMarkerModel m) {
    _stopNavigation();
    setState(() {
      _searchFocusCoord = m.location;
      _searchFocusName = m.title;
      _searchFocusPlace = m;
    });
    _mapCtrl.move(m.location, 17.0);
    _closeSearch();
    _rebuildMarkers();
    if (mounted) KakaoPlaceDetailSheet.show(context, m);
  }

  // ── 검색 ──────────────────────────────────────────────────────────────────

  List<CulturalEvent> get _searchResults {
    if (_searchQuery.length < 2) return [];
    final q = _searchQuery.toLowerCase();
    return _events
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _searchDebounce?.cancel();
    if (query.trim().length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        _runKakaoSearch(query);
        ref.read(unifiedSearchProvider.notifier).search(query);
      });
    }
  }

  void _selectResult(CulturalEvent event) {
    _stopNavigation();
    _mapCtrl.move(
      MapCoordinate(event.location.latitude, event.location.longitude),
      AppConstants.defaultZoom,
    );
    setState(() {
      _highlightedEventId = event.id;
      _searchFocusCoord = null;
      _searchFocusPlace = null;
    });
    _rebuildMarkers();
    _closeSearch();
    _showEventSheet(event);
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _searchQuery = '';
      _searchCtrl.clear();
    });
    ref.read(kakaoSearchProvider.notifier).clear();
    ref.read(unifiedSearchProvider.notifier).clear();
  }

  void _toggleSearch() {
    try {
      if (_searchOpen) {
        _closeSearch();
      } else {
        setState(() => _searchOpen = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchOpen) _searchFocus.requestFocus();
        });
      }
    } catch (_) {
      _closeSearch();
    }
  }

  void _updatePartnerPulse() {
    final hasPartner = _events.any((e) => e.source == EventSource.partner);
    if (hasPartner && !_partnerEventSeen) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  // ── 검색 패널 ──────────────────────────────────────────────────────────────

  void _runKakaoSearch(String query) {
    if (query.trim().length < 2) return;
    ref.read(kakaoSearchProvider.notifier).search(
          query: query,
          center: _centerCoord,
        );
    ref.read(unifiedSearchProvider.notifier).search(query);
  }

  Widget _buildSearchPanel() {
    final kakaoState = ref.watch(kakaoSearchProvider);
    final unifiedState = ref.watch(unifiedSearchProvider);
    final zgumItems = _searchResults;
    final remaining = (5 - zgumItems.length).clamp(0, 5);
    final kakaoItems = remaining > 0
        ? kakaoState.results.take(remaining).toList()
        : <MapMarkerModel>[];
    final kopisItems = unifiedState.kopisResults.take(5).toList();
    final tourItems = unifiedState.tourResults.take(5).toList();

    final bool hasAnyResult = zgumItems.isNotEmpty ||
        kakaoItems.isNotEmpty ||
        kopisItems.isNotEmpty ||
        tourItems.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14),
              cursorColor: AppColors.actionGold,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: null,
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFFBBBBBB), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFFBBBBBB), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          ref.read(kakaoSearchProvider.notifier).clear();
                          ref.read(unifiedSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _runKakaoSearch,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: _searchQuery.length < 2
              ? const Center(
                  child: Text(
                    '2글자 이상 입력하세요',
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // 주변 이벤트 (20km 내 로컬)
                    ...zgumItems.map((e) => _searchResultTile(
                          title: e.title,
                          subtitle: e.venue,
                          onTap: () => _selectResult(e),
                        )),
                    // 공연·행사 (KOPIS + Tour API 전국 검색)
                    if (unifiedState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBBBBBB),
                            ),
                          ),
                        ),
                      )
                    else if (kopisItems.isNotEmpty || tourItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '공연·행사',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                        ),
                      ),
                      ...kopisItems.map((r) => _searchResultTile(
                            title: r.title,
                            subtitle: '${r.venue}  ${r.startDate}~${r.endDate}',
                            onTap: () => _selectKopisResult(r),
                          )),
                      ...tourItems.map((e) => _searchResultTile(
                            title: e.title,
                            subtitle: e.venue,
                            onTap: () => _selectResult(e),
                          )),
                    ],
                    // 장소 (카카오)
                    if (kakaoState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBBBBBB),
                            ),
                          ),
                        ),
                      )
                    else if (kakaoState.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(kakaoState.error!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFCCCCCC))),
                      )
                    else ...[
                      if (kakaoItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            '장소',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA)),
                          ),
                        ),
                        ...kakaoItems.map((m) => _searchResultTile(
                              title: m.title,
                              subtitle: m.venue,
                              onTap: () => _selectKakaoPlace(m),
                            )),
                      ],
                      if (!hasAnyResult &&
                          kakaoState.hasSearched &&
                          unifiedState.hasSearched)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '결과가 없습니다',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFCCCCCC)),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _selectKopisResult(KopisSearchResult result) {
    // 이미 지도에 로드된 이벤트면 해당 마커로 이동
    final matched = _events.firstWhere(
      (e) => e.id == 'kopis_${result.mt20id}',
      orElse: () => _events.firstWhere(
        (e) => e.title == result.title,
        orElse: () => CulturalEvent(
          id: '',
          title: '',
          venue: '',
          address: '',
          description: '',
          startDate: DateTime.now(),
          endDateTime: DateTime.now(),
          location: _center,
          category: EventCategory.show,
          isFree: false,
          source: EventSource.public,
        ),
      ),
    );

    _closeSearch();

    if (matched.id.isNotEmpty) {
      _selectResult(matched);
      return;
    }

    // 지도에 없는 경우: 공연 정보 시트 표시
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.venue,
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.startDate} ~ ${result.endDate}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
            if (result.genre.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.genre,
                style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '현재 위치 반경 밖의 공연입니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResultTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF333333), fontSize: 14)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 12)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 18),
          ],
        ),
      ),
    );
  }

  // ── 길안내 ─────────────────────────────────────────────────────────────────

  Future<void> _startNavigation(CulturalEvent event) async {
    setState(() => _isLoadingRoute = true);
    try {
      final from = _center;
      final to = event.location;
      final url = 'http://router.project-osrm.org/route/v1/foot/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final res = await Dio().get<Map<String, dynamic>>(url);
      final coords = res.data!['routes'][0]['geometry']['coordinates'] as List;
      final points = coords
          .map((c) => MapCoordinate(c[1] as double, c[0] as double))
          .toList();
      if (!mounted) return;
      setState(() {
        _routeCoords = points;
        _isNavigating = true;
        _isLoadingRoute = false;
      });
      _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로를 불러오지 못했습니다. 잠시 후 다시 시도하세요.')),
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _routeCoords = [];
      _isNavigating = false;
      _isLoadingRoute = false;
    });
  }

  Future<void> _showEventSheet(CulturalEvent event) async {
    if (!mounted) return;
    final myEventIds =
        ref.read(partnerMyEventsProvider).map((e) => e.id).toSet();
    final activeEvent = ref.read(activePartnerEventProvider);
    final isMyEvent =
        myEventIds.contains(event.id) || activeEvent?.id == event.id;
    EventDetailSheet.show(
      context,
      event,
      timeService: _timeService,
      userLocation: _center,
      isCheckedIn: ref
          .read(checkInProvider.notifier)
          .checkedInEventIds
          .contains(event.id),
      onCheckIn: isMyEvent
          ? null
          : (String? memo, String? photoPath) {
              final record = CheckInRecord.fromEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                eventId: event.id,
                eventTitle: event.title,
                venue: event.venue,
                category: event.category,
                checkedInAt: DateTime.now(),
                memo: memo,
                photoPath: photoPath,
              );
              ref.read(checkInProvider.notifier).save(record);
              _rebuildMarkers();
            },
      onNavigate: (_isNavigating || _isLoadingRoute)
          ? null
          : () => _startNavigation(event),
    );
  }

  void _onMarkerTap(MapMarkerModel marker) {
    debugPrint('[MapRoom] _onMarkerTap: ${marker.id} / ${marker.title}');
    if (marker.id == _searchPinId) {
      final place = _searchFocusPlace;
      if (place != null && mounted) KakaoPlaceDetailSheet.show(context, place);
      return;
    }
    final event = _eventById[marker.id];
    if (event == null) {
      debugPrint('[MapRoom] marker event missing: ${marker.id}');
      return;
    }
    final activeOwnEvent = ref.read(activePartnerEventProvider);
    if (activeOwnEvent != null && activeOwnEvent.id == event.id) return;
    debugPrint('[MapRoom] show sheet: ${event.id} / ${event.title}');
    _mapCtrl.move(
      MapCoordinate(event.location.latitude, event.location.longitude),
      AppConstants.defaultZoom,
    );
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (!mounted) return;
      await _showEventSheet(event);
      if (mounted) _rebuildMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<AsyncValue<List<PartnerEvent>>>(
        activePartnerEventsStreamProvider, (prev, next) {
      _loadEvents();
    });
    ref.listen<PartnerEvent?>(activePartnerEventProvider, (prev, next) {
      if (prev != null && next == null) _loadEvents();
    });
    ref.listen<MapFilterState>(mapFilterProvider, (_, __) => _rebuildMarkers());
    ref.listen<AuthState>(authStateProvider, (_, __) => _loadEvents());
    ref.listen<CulturalEvent?>(partnerFocusProvider, (prev, next) {
      if (next != null) _focusPartnerEvent(next);
    });
    ref.listen<int>(shellPageProvider, (prev, next) {
      if (next == 1 && prev != 1) {
        if (!ref.read(partnerFocusPendingProvider) && !_isNavigating) {
          recenterOnUser();
        }
      }
    });

    final safePadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSearchPanelHeight =
        (screenHeight - safePadding - bottomPadding - 120)
            .clamp(220.0, double.infinity)
            .toDouble();
    final panelHeight =
        (screenHeight * 0.48).clamp(220.0, maxSearchPanelHeight).toDouble();
    final kakaoResults = ref.watch(kakaoSearchProvider).results;
    final hasResults = _searchQuery.isNotEmpty &&
        (kakaoResults.isNotEmpty || _searchResults.isNotEmpty);
    final searchPanelHeight = !_searchOpen
        ? 48.0
        : hasResults
            ? panelHeight
            : 120.0;
    final routeButtonIsEnd = _isNavigating && !_isLoadingRoute;
    final routeButtonBg = routeButtonIsEnd
        ? AppColors.actionGoldSoft.withValues(alpha: 0.96)
        : AppColors.actionGold;
    final routeButtonFg =
        routeButtonIsEnd ? AppColors.actionGoldText : Colors.white;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 지도 ──────────────────────────────────────────────────────
          Positioned.fill(
            child: _engine.buildWidget(
              initialCenter: _centerCoord,
              initialZoom: AppConstants.defaultZoom,
              markers: _markers,
              onMarkerTap: _onMarkerTap,
              controller: _mapCtrl,
              userLocation: _centerCoord,
              routePoints: _routeCoords.isEmpty ? null : _routeCoords,
              onEngineReady: widget.onMapReady,
            ),
          ),
          if (!_searchOpen) ...[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width *
                  ShellGestureLayoutSpec.current.mapEdgeSwipeWidthFactor,
              child: GestureDetector(
                behavior: Platform.isIOS
                    ? HitTestBehavior.translucent
                    : HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) >
                      ShellGestureLayoutSpec.current.mapEdgeSwipeVelocity) {
                    widget.onSwipeToUserRoom?.call();
                  }
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width *
                  ShellGestureLayoutSpec.current.mapEdgeSwipeWidthFactor,
              child: GestureDetector(
                behavior: Platform.isIOS
                    ? HitTestBehavior.translucent
                    : HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) <
                      -ShellGestureLayoutSpec.current.mapEdgeSwipeVelocity) {
                    widget.onSwipeToPartnerRoom?.call();
                  }
                },
              ),
            ),
          ],

          // ── 검색: 빈공간 터치 닫기 (전체 화면 커버, 검색 패널 뒤에 위치) ──
          if (_searchOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeSearch,
              ),
            ),

          // ── 검색 패널 (탭으로 열기) ────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: 0,
            left: 0,
            right: 0,
            height: safePadding + searchPanelHeight,
            child: Container(
              padding: EdgeInsets.only(top: safePadding),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: _searchOpen
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.transparent,
                boxShadow: _searchOpen
                    ? const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: _searchOpen
                  ? LayoutBuilder(
                      builder: (ctx, constraints) {
                        if (constraints.maxHeight < 100) {
                          return const SizedBox.shrink();
                        }
                        return _buildSearchPanel();
                      },
                    )
                  : GestureDetector(
                      onTap: _toggleSearch,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: _locationAcquiring
                              ? const CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  color: AppColors.actionGoldBright,
                                )
                              : Center(
                                  child: Container(
                                    width: 20,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.actionGoldBright
                                          .withValues(alpha: 0.70),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
            ),
          ),

          if (_isLoadingRoute || _isNavigating)
            Positioned(
              bottom: bottomPadding + 48,
              right: 16,
              child: GestureDetector(
                onTap: _isNavigating ? _stopNavigation : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: routeButtonBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoadingRoute
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '경로 탐색 중...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: routeButtonFg, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '안내 종료',
                              style: TextStyle(
                                color: routeButtonFg,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // ── 수동 위치 설정 모드 ────────────────────────────────────────
          if (_needsManualLocation) ...[
            Positioned(
              top: safePadding + 56,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.actionGold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '지도를 움직여 내 위치를 설정하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.add,
                size: 36,
                color: AppColors.actionGold,
              ),
            ),
            Positioned(
              bottom: bottomPadding + 48,
              left: 48,
              right: 48,
              child: FilledButton(
                onPressed: _confirmManualLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionGold,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '이 위치로 설정',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          // 지금 버튼 → ShellScreen 공통 하단 탭으로 이전됨
        ],
      ),
    );
  }
}
