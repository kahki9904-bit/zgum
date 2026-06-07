import 'dart:async';
import 'dart:math' show cos, pow;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants.dart';
import '../../../core/event_fade.dart';
import '../../../core/geo_utils.dart';
import '../../../core/interfaces/map_engine.dart';
import '../../../core/models/map_marker_model.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/tick_provider.dart';
import '../../../data/adapters/cultural_event_adapter.dart';
import '../../../data/models/cultural_event.dart';
import '../../../core/app_config.dart';
import '../../../data/repositories/api_cultural_event_repository.dart';
import '../../../data/repositories/cultural_event_repository.dart';
import '../../../data/repositories/mock_cultural_event_repository.dart';
import '../../../data/repositories/sdsc_store_repository.dart';
import '../../../services/location_service.dart';
import '../../../services/time_service.dart';
import '../../../presentation/widgets/sheets/event_detail_sheet.dart';
import '../../user_room/providers/auth_provider.dart';
import '../../../data/models/check_in_record.dart';
import '../../user_room/providers/check_in_provider.dart';
import '../engines/flutter_map_engine.dart';
import '../providers/map_filter_provider.dart';

class MapRoomScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwipeToUserRoom;
  final VoidCallback? onSwipeToPartnerRoom;

  const MapRoomScreen({
    super.key,
    this.onSwipeToUserRoom,
    this.onSwipeToPartnerRoom,
  });

  @override
  ConsumerState<MapRoomScreen> createState() => MapRoomScreenState();
}

class MapRoomScreenState extends ConsumerState<MapRoomScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── 지도 엔진 (여기만 바꾸면 지도 교체 완료) ─────────────────────────────────
  final MapEngine _engine = FlutterMapEngine();

  final _locationService = LocationService();
  final CulturalEventRepository _publicRepo = MockCulturalEventRepository();
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

  Offset? _swipeStart;

  // ── 검색 ──────────────────────────────────────────────────────────────────
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  String? _highlightedEventId;

  // ── 지금 패널 ──────────────────────────────────────────────────────────────
  bool _nowPanelOpen = false;

  // ── GPS 상태 ───────────────────────────────────────────────────────────────
  bool _locationAcquiring = true;
  bool _needsManualLocation = false;
  LocationStep _locationStep = LocationStep.gps;

  // ── 체크인 (checkInProvider에서 관리) ────────────────────────────────────

  // ── 경로 안내 ──────────────────────────────────────────────────────────────
  List<MapCoordinate> _routeCoords = [];
  bool _isNavigating = false;
  bool _isLoadingRoute = false;

  // ── 친구 흔적 mock 데이터 (Firebase 연동 전 임시) ────────────────────────────
  static const _mockFriendTrace = <String, int>{
    'test-001': 2,
    'pub-004': 1,
    'par-001': 3,
  };

  @override
  void initState() {
    super.initState();
    _mapCtrl = _engine.createController();
    _init();
  }

  @override
  void dispose() {
    for (final t in _eventTimers.values) {
      t.cancel();
    }
    _eventTimers.clear();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void recenterOnUser() {
    if (!mounted || _locationAcquiring) return;
    _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);
  }

  Future<void> _init() async {
    final result = await _locationService.acquireLocation();
    if (!mounted) return;
    setState(() {
      _center = result.position;
      _locationStep = result.step;
      _locationAcquiring = false;
      _needsManualLocation = result.needsManual;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);
    });
    if (!result.needsManual) await _loadEvents();
  }

  void _confirmManualLocation() {
    setState(() => _needsManualLocation = false);
    _locationService.saveLastKnown(_center);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final isIdentityVerified =
          ref.read(authStateProvider).isIdentityVerified;
      final args = (
        center: _center,
        radiusKm: AppConstants.defaultRadiusKm,
        isIdentityVerified: isIdentityVerified,
      );
      final results = await Future.wait([
        _publicRepo.fetchNearbyEvents(
          center: args.center,
          radiusKm: args.radiusKm,
          isIdentityVerified: args.isIdentityVerified,
        ),
        if (_partnerRepo != null)
          _partnerRepo.fetchNearbyEvents(
            center: args.center,
            radiusKm: args.radiusKm,
            isIdentityVerified: args.isIdentityVerified,
          ),
      ]);
      final all = results.expand((list) => list).toList();
      final now = _timeService.now();
      final active = all
          .where((e) => !EventFade.isFullyExpired(e.endDateTime, now))
          .toList();
      if (!mounted) return;
      setState(() {
        _events = active;
        _eventById = {for (final e in active) e.id: e};
      });
      _scheduleEventTimers(active);
      _rebuildMarkers();
    } on CulturalEventApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: '재시도', onPressed: _loadEvents),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('데이터를 불러오지 못했습니다. 잠시 후 다시 시도하세요.'),
        duration: Duration(seconds: 5),
      ));
    }
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
      _eventTimers[event.id] =
          Timer(delay, () => _expireEventNow(event.id));
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

  // ── 표시 이벤트 필터링 ──────────────────────────────────────────────────────

  List<CulturalEvent> _visibleEvents(MapFilterState filter) {
    return _events.where((e) {
      // 파트너 이벤트(과금 상태)는 거리 제한 없이 항상 표시
      if (e.source == EventSource.partner) return filter.passes(e);
      if (walkingMinutes(_center, e.location) > filter.walkingMinutes) {
        return false;
      }
      return filter.passes(e);
    }).toList();
  }

  void _rebuildMarkers() {
    if (!mounted) return;
    final filter = ref.read(mapFilterProvider);
    final visible = _visibleEvents(filter);

    final markers = CulturalEventAdapter.toMarkers(visible)
        .map((m) {
          final isHL = m.id == _highlightedEventId;
          final isCI = ref.read(checkInProvider.notifier).checkedInEventIds.contains(m.id);
          if (!isHL && !isCI) return m;
          return MapMarkerModel(
            id: m.id,
            location: m.location,
            category: m.category,
            deadline: m.deadline,
            isAdultOnly: m.isAdultOnly,
            title: m.title,
            venue: m.venue,
            isPartner: m.isPartner,
            isHighlighted: true,
            payload: m.payload,
          );
        })
        .toList();

    setState(() => _markers = markers);
  }

  // ── 검색 ──────────────────────────────────────────────────────────────────

  List<CulturalEvent> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _events
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _selectResult(CulturalEvent event) {
    _mapCtrl.move(
      MapCoordinate(event.location.latitude, event.location.longitude),
      AppConstants.defaultZoom,
    );
    setState(() => _highlightedEventId = event.id);
    _rebuildMarkers();
    _closeSearch();
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _toggleSearch() {
    if (_searchOpen) {
      _closeSearch();
    } else {
      if (_nowPanelOpen) setState(() => _nowPanelOpen = false);
      setState(() => _searchOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchOpen) _searchFocus.requestFocus();
      });
    }
  }

  void _toggleNowPanel() {
    if (_nowPanelOpen) {
      setState(() => _nowPanelOpen = false);
    } else {
      if (_searchOpen) _closeSearch();
      setState(() => _nowPanelOpen = true);
    }
  }

  // ── 지금 패널 ──────────────────────────────────────────────────────────────

  Widget _buildNowPanel(MapFilterState filter) {
    final visible = _visibleEvents(filter);
    return _NowPanelContent(
      visible: visible,
      center: _center,
      onEventTap: _focusEvent,
    );
  }

  void _focusEvent(CulturalEvent event) {
    // 하단 시트가 화면 약 45%를 가리므로 마커가 시트 위에 보이도록 중심을 남쪽으로 내림
    final screenHeight = MediaQuery.of(context).size.height;
    const sheetRatio = 0.45;
    final offsetPx = screenHeight * sheetRatio / 2;
    final lat = event.location.latitude;
    final metersPerPx = 156543.03392 * cos(lat * pi / 180) /
        pow(2, AppConstants.defaultZoom);
    final latOffset = offsetPx * metersPerPx / 111320;

    _mapCtrl.move(
      MapCoordinate(lat - latOffset, event.location.longitude),
      AppConstants.defaultZoom,
    );
    setState(() {
      _highlightedEventId = event.id;
      _nowPanelOpen = false;
    });
    _rebuildMarkers();
    if (mounted) {
      EventDetailSheet.show(
        context,
        event,
        timeService: _timeService,
        userLocation: _center,
        isCheckedIn: ref.read(checkInProvider.notifier).checkedInEventIds.contains(event.id),
        friendTraceCount: _mockFriendTrace[event.id] ?? 0,
        onCheckIn: (String? memo, String? photoPath) {
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
  }

  // ── 검색 패널 ──────────────────────────────────────────────────────────────

  Widget _buildSearchPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style:
                  const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14),
              cursorColor: const Color(0xFF16213E),
              decoration: InputDecoration(
                hintText: '공연명 또는 장소 검색',
                hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFFBBBBBB), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFFBBBBBB), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다',
                      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final e = _searchResults[i];
                      return InkWell(
                        onTap: () => _selectResult(e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.title,
                                      style: const TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      e.venue,
                                      style: const TextStyle(
                                        color: Color(0xFFAAAAAA),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFDDDDDD),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
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
      final coords =
          res.data!['routes'][0]['geometry']['coordinates'] as List;
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
        const SnackBar(
            content: Text('경로를 불러오지 못했습니다. 잠시 후 다시 시도하세요.')),
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _routeCoords = [];
      _isNavigating = false;
    });
  }

  void _onMarkerTap(MapMarkerModel marker) {
    final event = _eventById[marker.id];
    if (event != null && mounted) {
      EventDetailSheet.show(
        context,
        event,
        timeService: _timeService,
        userLocation: _center,
        isCheckedIn: ref.read(checkInProvider.notifier).checkedInEventIds.contains(event.id),
        friendTraceCount: _mockFriendTrace[event.id] ?? 0,
        onCheckIn: (String? memo, String? photoPath) {
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<MapFilterState>(
        mapFilterProvider, (_, __) => _rebuildMarkers());
    ref.listen<AuthState>(
        authStateProvider, (_, __) => _loadEvents());
    final filter = ref.watch(mapFilterProvider);

    final safePadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = screenHeight * 0.5;
    const nowPanelHeight = 240.0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 지도 ──────────────────────────────────────────────────────
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _swipeStart = e.localPosition,
            onPointerUp: (e) {
              if (_searchOpen) return;
              final start = _swipeStart;
              _swipeStart = null;
              if (start == null) return;
              final dx = e.localPosition.dx - start.dx;
              final dy = e.localPosition.dy - start.dy;
              if (dx.abs() < dy.abs() * 1.2) return;
              final sw = MediaQuery.sizeOf(context).width;
              if (start.dx < 72 && dx > 64) {
                widget.onSwipeToUserRoom?.call();
              }
              if (start.dx > sw - 72 && dx < -64) {
                widget.onSwipeToPartnerRoom?.call();
              }
            },
            onPointerCancel: (_) => _swipeStart = null,
            child: _engine.buildWidget(
              initialCenter: _centerCoord,
              initialZoom: AppConstants.defaultZoom,
              markers: _markers,
              onMarkerTap: _onMarkerTap,
              controller: _mapCtrl,
              userLocation: _centerCoord,
              routePoints:
                  _routeCoords.isEmpty ? null : _routeCoords,
            ),
          ),

          // ── 검색: 빈공간 터치 닫기 ────────────────────────────────────
          if (_searchOpen)
            Positioned(
              top: safePadding + (_searchQuery.isNotEmpty ? panelHeight : 60.0),
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeSearch,
              ),
            ),

          // ── 검색 패널 (상단 스와이프로 열기) ──────────────────────────
          Column(
            children: [
              SizedBox(height: safePadding),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v > 150 && !_searchOpen) _toggleSearch();
                  if (v < -150 && _searchOpen) _closeSearch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  height: !_searchOpen
                      ? 28
                      : _searchQuery.isNotEmpty
                          ? panelHeight
                          : 60.0,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: _searchOpen ? Colors.white : Colors.transparent,
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
                      ? _buildSearchPanel()
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),

          // ── 경로 탐색 중 / 안내 종료 버튼 ─────────────────────────────
          if (_isLoadingRoute || _isNavigating)
            Positioned(
              bottom: bottomPadding + 48,
              right: 16,
              child: GestureDetector(
                onTap: _isNavigating ? _stopNavigation : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
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
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '안내 종료',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // ── GPS 획득 중 표시 ───────────────────────────────────────────
          if (_locationAcquiring)
            Positioned(
              top: safePadding + 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '위치를 찾는 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 유추 위치 안내 배너 ────────────────────────────────────────
          if (!_locationAcquiring && !_needsManualLocation &&
              (_locationStep == LocationStep.lastKnown ||
                  _locationStep == LocationStep.network))
            Positioned(
              top: safePadding + 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD580)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_searching,
                          size: 13, color: Color(0xFFFF8C00)),
                      const SizedBox(width: 6),
                      Text(
                        _locationStep == LocationStep.lastKnown
                            ? '이전 위치 기준으로 표시 중'
                            : '대략적인 위치로 표시 중',
                        style: const TextStyle(
                          color: Color(0xFF996600),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E).withValues(alpha: 0.9),
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
                color: Color(0xFF16213E),
              ),
            ),
            Positioned(
              bottom: bottomPadding + 48,
              left: 48,
              right: 48,
              child: FilledButton(
                onPressed: _confirmManualLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '이 위치로 설정',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          // ── 지금 패널: 빈공간 터치 닫기 ──────────────────────────────
          if (_nowPanelOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: nowPanelHeight + bottomPadding + 32,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleNowPanel,
              ),
            ),

          // ── 지금 패널 (하단 스와이프로 열기) ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 200 &&
                        _nowPanelOpen) {
                      _toggleNowPanel();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: _nowPanelOpen ? nowPanelHeight : 0,
                    color: Colors.white,
                    child: _nowPanelOpen
                        ? _buildNowPanel(filter)
                        : const SizedBox.shrink(),
                  ),
                ),
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v < -200 && !_nowPanelOpen) _toggleNowPanel();
                    if (v > 200 && _nowPanelOpen) _toggleNowPanel();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 32,
                    color: Colors.transparent,
                  ),
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 지금 패널 콘텐츠 (tickProvider 구독 — 1초마다 자체 갱신) ─────────────────────

class _NowPanelContent extends ConsumerWidget {
  final List<CulturalEvent> visible;
  final LatLng center;
  final void Function(CulturalEvent) onEventTap;

  const _NowPanelContent({
    required this.visible,
    required this.center,
    required this.onEventTap,
  });

  String _formatRemaining(DateTime endDateTime, DateTime now) {
    final neg = EventFade.negativeLabel(endDateTime, now);
    if (neg != null) return neg;
    final remaining = endDateTime.difference(now);
    if (remaining.inDays >= 1) return '${remaining.inDays}일';
    if (remaining.inHours >= 1) return '${remaining.inHours}시간';
    return '${remaining.inMinutes}분';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(tickProvider);
    final now = tick.value ?? DateTime.now();

    final sorted = [...visible];
    sorted.sort((a, b) {
      final aR = a.endDateTime.difference(now);
      final bR = b.endDateTime.difference(now);
      if (!aR.isNegative && bR.isNegative) return -1;
      if (aR.isNegative && !bR.isNegative) return 1;
      if (aR.isNegative) return bR.compareTo(aR); // 종료됨: 최근 종료 순
      return aR.compareTo(bR); // 활성: 마감 임박 순
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                context.l10n.panelTitle,
                style: const TextStyle(
                  color: Color(0xFF16213E),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.momentCount(sorted.length),
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ],
          ),
        ),
        if (sorted.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                context.l10n.noMomentsNearby,
                style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: sorted.length,
              separatorBuilder: (_, __) =>
                  Container(height: 1, color: const Color(0xFFF5F5F5)),
              itemBuilder: (_, i) {
                final event = sorted[i];
                final mins = walkingMinutes(center, event.location);
                final isPartner = event.source == EventSource.partner;
                final isPostEnd =
                    now.isAfter(event.endDateTime);
                final isGrayed =
                    EventFade.isGrayed(event.endDateTime, now);
                final fade =
                    EventFade.opacity(event.endDateTime, now);
                final timeLabel =
                    _formatRemaining(event.endDateTime, now);

                final dotColor = isGrayed
                    ? const Color(0xFFBBBBBB)
                    : isPartner
                        ? const Color(0xFFFF8C00)
                        : const Color(0xFF16213E).withValues(alpha: 0.3);
                final titleColor = isGrayed
                    ? const Color(0xFFBBBBBB)
                    : const Color(0xFF333333);
                final timeColor = isPostEnd
                    ? const Color(0xFF999999)
                    : const Color(0xFF16213E);

                return Opacity(
                  opacity: fade,
                  child: GestureDetector(
                    onTap: () => onEventTap(event),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isPartner
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPartner ? context.l10n.partnerBadge : context.l10n.walkingMinutes(mins),
                            style: TextStyle(
                              fontSize: 11,
                              color: isGrayed
                                  ? const Color(0xFFCCCCCC)
                                  : isPartner
                                      ? const Color(0xFFFF8C00)
                                      : const Color(0xFFBBBBBB),
                              fontWeight: isPartner
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
