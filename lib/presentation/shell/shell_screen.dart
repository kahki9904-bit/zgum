import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/partner_focus_provider.dart';
import '../../core/providers/shell_page_provider.dart';
import '../../core/providers/partner_my_events_provider.dart';
import '../../core/providers/user_location_provider.dart';
import '../../data/models/check_in_record.dart';
import '../../data/models/cultural_event.dart';
import '../../dev/mock_partner_event_store.dart';
import '../../features/alert/models/partner_event.dart';
import '../../features/friend/data/models/friend_request.dart';
import '../../features/friend/providers/friend_provider.dart';
import '../../services/location_service.dart';
import '../../features/alert/providers/alert_provider.dart';
import '../../features/alert/providers/geofence_provider.dart';
import '../../features/map_room/screens/map_room_screen.dart';
import '../../features/partner_room/screens/partner_room_screen.dart';
import '../../features/user_room/providers/check_in_provider.dart';
import '../../features/user_room/screens/user_room_screen.dart';
import '../widgets/trace_checkin_dialog.dart';
import '../widgets/dialogs/ieum_accept_dialog.dart';
import '../widgets/dialogs/ieum_request_dialog.dart';
import '../../services/gesture_exclusion_service.dart';
import '../../core/providers/active_partner_event_provider.dart';
import '../../core/providers/admin_mode_provider.dart';
import '../../promotions/free_use/free_use_service.dart';
import '../../promotions/free_use/free_use_intro_popup.dart';
import '../../promotions/free_use/free_use_alert_popup.dart';
import '../../features/friend/widgets/ieum_intro_popup.dart';
import '../widgets/dialogs/camera_chooser_popup.dart';
import '../widgets/dialogs/zgum_dialog.dart';
import '../../services/firestore_partner_event_service.dart';

// 지금 패널/캡슐 크기 상수 (file-level — _NowBundle에서도 사용)
const double _kCapsuleHeight = 40.0;
const double _kPanelFloat = 30.0;
const double _kPanelHandleContentGap = 44.0;

// iOS 홈 제스처 충돌 시 이 값을 8~20 사이로 올리세요 (현재 0 = 안전구역만 사용)
const double _kIosGestureBuffer = 0.0;

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _pc = PageController(initialPage: 1);
  final _mapKey = GlobalKey<MapRoomScreenState>();
  int _page = 1;
  bool _tracePopupShowing = false;
  // ValueNotifier: 패널 열림 상태 변경이 PageView rebuild를 유발하지 않도록 분리
  final _nowPanelOpen = ValueNotifier<bool>(false);
  // AnimationController: Transform.translate 기반 — 레이아웃 변경 없이 페인트만 이동
  late final AnimationController _panelAnim;
  double panelHeight = 300.0;
  bool _tabVisible = false;
  bool _showNowTab = false;
  bool _mapReady = false;

  void _onRouteAnimationComplete() {
    setState(() => _tabVisible = true);
    // 지도가 onMapReady 신호를 보내면 _onMapReady()가 먼저 처리.
    // 6초 안전장치: 신호가 오지 않을 경우 강제 표시.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_showNowTab) setState(() => _showNowTab = true);
    });
  }

  void _onMapReady() {
    if (!mounted) return;
    setState(() {
      _showNowTab = true;
      _mapReady = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final result = await FreeUseService.instance.syncNotificationStatus();
    if (!mounted) return;
    if (result == NotificationSyncResult.paused) {
      showFreeUseAlertPopup(context);
    } else if (result == NotificationSyncResult.resumed) {
      showFreeUseResumedPopup(context);
    }
  }

  Future<void> _showIntroIfNeeded() async {
    final shown = await FreeUseService.instance.isIntroShown();
    if (!shown) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) await showFreeUseIntroPopup(context);
    }
    // 인트로 확인 후 현재 알림 상태 체크 → 이미 허용 중이면 크레딧 즉시 시작
    if (mounted) await _checkNotificationStatus();
  }

  Future<void> _showFreeUseIntroIfNeeded() async {
    final shown = await FreeUseService.instance.isIntroShown();
    if (!shown && mounted) showFreeUseIntroPopup(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _panelAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showIntroIfNeeded();
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.status == AnimationStatus.completed) {
        _onRouteAnimationComplete();
      } else {
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed && mounted) {
            _onRouteAnimationComplete();
            animation.removeStatusListener(listener);
          }
        }

        animation.addStatusListener(listener);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _syncExclusionRects();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GestureExclusionService.clearExclusionRects();
    _pc.dispose();
    _nowPanelOpen.dispose();
    _panelAnim.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pc.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncExclusionRects();
      if (page == 1 && !ref.read(partnerFocusPendingProvider)) {
        _mapKey.currentState?.recenterOnUser();
      }
    });
  }

  void _syncExclusionRects() {
    if (!mounted) return;
    if (_page != 1) {
      GestureExclusionService.clearExclusionRects();
      return;
    }
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const w = 40.0;
    GestureExclusionService.setExclusionRects([
      Rect.fromLTWH(0, 0, w, size.height),
      Rect.fromLTWH(size.width - w, 0, w, size.height),
    ], dpr);
  }

  void _closeNow() {
    if (!_nowPanelOpen.value) return;
    _nowPanelOpen.value = false;
    final rem = _panelAnim.value;
    _panelAnim.animateTo(0.0,
        duration: Duration(milliseconds: (rem * 280).round().clamp(80, 280)),
        curve: Curves.easeIn);
  }

  void _toggleNow() {
    if (_nowPanelOpen.value) {
      _closeNow();
    } else {
      _nowPanelOpen.value = true;
      final rem = 1.0 - _panelAnim.value;
      _panelAnim.animateTo(1.0,
          duration: Duration(milliseconds: (rem * 300).round().clamp(80, 300)),
          curve: Curves.easeOut);
      _navigateToAlertIfNeeded();
    }
  }

  void _onNowDragUpdate(DragUpdateDetails d) {
    final maxDist = panelHeight + _kPanelFloat;
    _panelAnim.value =
        (_panelAnim.value - (d.primaryDelta ?? 0) / maxDist).clamp(0.0, 1.0);
  }

  void _onNowDragEnd(DragEndDetails d) {
    final vel = d.primaryVelocity ?? 0;
    if (vel < -300 || (_panelAnim.value >= 0.4 && vel < 300)) {
      _nowPanelOpen.value = true;
      final rem = 1.0 - _panelAnim.value;
      _panelAnim.animateTo(1.0,
          duration: Duration(milliseconds: (rem * 300).round().clamp(80, 300)),
          curve: Curves.easeOut);
      _navigateToAlertIfNeeded();
    } else {
      _nowPanelOpen.value = false;
      final rem = _panelAnim.value;
      _panelAnim.animateTo(0.0,
          duration: Duration(milliseconds: (rem * 280).round().clamp(80, 280)),
          curve: Curves.easeIn);
    }
  }

  void _navigateToAlertIfNeeded() {
    final alerts = (ref
        .read(partnerAlertProvider)
        .where((e) => !e.seen && !e.isExpired)
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt)));
    if (alerts.isEmpty) return;

    final event = alerts.first;
    final cultural = CulturalEvent(
      id: event.id,
      title: event.title,
      venue: event.venue,
      address: '현재 위치',
      description: event.title,
      startDate: event.startsAt,
      endDateTime: event.expiresAt,
      location: event.location,
      category: EventCategory.partner,
      isFree: false,
      source: EventSource.partner,
      partnerMessage: event.message,
    );
    final store = ref.read(mockPartnerEventStoreProvider);
    if (!store.any((e) => e.id == cultural.id)) {
      ref.read(mockPartnerEventStoreProvider.notifier).state = [
        ...store,
        cultural
      ];
    }
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = cultural;
    ref.read(partnerAlertProvider.notifier).markAsSeen(event.id);
  }

  /// 지오펜스 3분 체류 달성 시 자동으로 흔적 팝업 표시
  void _showTracePopup(PartnerEvent event) {
    if (_tracePopupShowing || !mounted) return;
    _tracePopupShowing = true;
    showTraceCheckInDialog(context, event)
        .whenComplete(() => _tracePopupShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    // 지오펜스 상태 변화 감지 → 자동 팝업 (어느 탭에 있어도 작동)
    ref.listen<PartnerEvent?>(geofenceProvider, (prev, next) {
      if (next != null && prev == null) {
        _showTracePopup(next);
      }
    });

    // shellPageProvider 변화 감지 → 페이지 이동
    ref.listen<int>(shellPageProvider, (prev, next) {
      if (prev != next) _goTo(next);
    });

    final hasAlert = ref.watch(hasUnseenAlertProvider);
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    panelHeight = (availableHeight * 0.68).clamp(420.0, 560.0);
    final bottomPadding =
        max(media.padding.bottom, Platform.isAndroid ? 16.0 : 0.0) +
            _kIosGestureBuffer;

    return ValueListenableBuilder<bool>(
      valueListenable: _nowPanelOpen,
      builder: (_, panelOpen, child) => PopScope(
        canPop: !panelOpen && _page == 1,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (panelOpen) {
            _closeNow();
          } else {
            _goTo(1);
          }
        },
        child: child!,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pc,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) {
                setState(() => _page = p);
                ref.read(shellPageProvider.notifier).state = p;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _syncExclusionRects());
                if (p == 2) _showFreeUseIntroIfNeeded();
              },
              children: [
                _SwipeWrapper(
                  onSwipeLeft: () => _goTo(1),
                  onSwipeRight: null,
                  child: const UserRoomScreen(),
                ),
                MapRoomScreen(
                  key: _mapKey,
                  onSwipeToUserRoom: () => _goTo(0),
                  onSwipeToPartnerRoom: () => _goTo(2),
                  onMapReady: _onMapReady,
                ),
                _SwipeWrapper(
                  onSwipeLeft: null,
                  onSwipeRight: () => _goTo(1),
                  child: const PartnerRoomScreen(),
                ),
              ],
            ),
          ),
          // 메인 화면 안정화 이후에만 패널 표시
          // RepaintBoundary를 최상위에 배치 — 패널 애니메이션이 지도 레이어 repaint를 유발하지 않도록 격리
          if (_tabVisible)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showNowTab ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showNowTab,
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _nowPanelOpen,
                      builder: (_, isOpen, __) => Stack(
                        children: [
                          // 열린 상태: 패널 위쪽 전체 탭 or 아래로 드래그 → 닫기
                          if (isOpen)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: bottomPadding + panelHeight,
                              child: GestureDetector(
                                onTap: _closeNow,
                                onVerticalDragUpdate: _onNowDragUpdate,
                                onVerticalDragEnd: _onNowDragEnd,
                                behavior: HitTestBehavior.opaque,
                              ),
                            ),

                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: Platform.isIOS ? 0 : bottomPadding,
                            height: Platform.isIOS
                                ? panelHeight +
                                    _kCapsuleHeight +
                                    _kPanelFloat +
                                    bottomPadding
                                : panelHeight + _kCapsuleHeight + _kPanelFloat,
                            child: AnimatedBuilder(
                              animation: _panelAnim,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  (1.0 - _panelAnim.value) *
                                      (panelHeight + _kPanelFloat),
                                ),
                                child: child,
                              ),
                              child: _NowBundle(
                                isOpen: isOpen,
                                hasAlert: hasAlert,
                                panelHeight: panelHeight,
                                bottomPadding:
                                    Platform.isIOS ? bottomPadding : 0,
                                onToggle: Platform.isIOS ? _toggleNow : null,
                                panelAnim: _panelAnim,
                                currentPage: _page,
                                mapReady: _mapReady,
                                onDragUpdate: _onNowDragUpdate,
                                onDragEnd: _onNowDragEnd,
                                onClose: _closeNow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _SwipeWrapper({
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<_SwipeWrapper> createState() => _SwipeWrapperState();
}

class _SwipeWrapperState extends State<_SwipeWrapper> {
  double? _startX;
  double? _startY;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _startX = e.position.dx;
          _startY = e.position.dy;
          _triggered = false;
        },
        onPointerMove: (e) {
          if (_triggered || _startX == null || _startY == null) return;
          final dx = e.position.dx - _startX!;
          final dy = (e.position.dy - _startY!).abs();
          if (dx.abs() < 60 || dx.abs() < dy * 1.2) return;
          _triggered = true;
          _startX = null;
          _startY = null;
          if (dx < 0) widget.onSwipeLeft?.call();
          if (dx > 0) widget.onSwipeRight?.call();
        },
        onPointerUp: (_) {
          _startX = null;
          _startY = null;
          _triggered = false;
        },
        onPointerCancel: (_) {
          _startX = null;
          _startY = null;
          _triggered = false;
        },
        child: widget.child,
      ),
    );
  }
}

class _NowBundle extends StatelessWidget {
  final bool isOpen;
  final bool hasAlert;
  final double panelHeight;
  final double bottomPadding;
  final VoidCallback? onToggle;
  final Animation<double> panelAnim;
  final int currentPage;
  final bool mapReady;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onClose;

  const _NowBundle({
    required this.isOpen,
    required this.hasAlert,
    required this.panelHeight,
    required this.bottomPadding,
    required this.panelAnim,
    required this.currentPage,
    required this.mapReady,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onClose,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildPanelContent();

    if (onToggle != null) {
      return _IosNowBundle(
        isOpen: isOpen,
        hasAlert: hasAlert,
        panelHeight: panelHeight,
        bottomPadding: bottomPadding,
        panelAnim: panelAnim,
        mapReady: mapReady,
        onToggle: onToggle!,
        content: content,
      );
    }

    return _AndroidNowBundle(
      hasAlert: hasAlert,
      panelHeight: panelHeight,
      panelAnim: panelAnim,
      mapReady: mapReady,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      content: content,
    );
  }

  Widget _buildPanelContent() {
    switch (currentPage) {
      case 2: // 이곳 — 열렸을 때만 생성 (initState에서 카메라 트리거)
        if (!isOpen) return const SizedBox.shrink();
        return _PartnerPanelContent(onClose: onClose);
      case 0: // 사용자
        return _UserPanelContent(onClose: onClose);
      default: // 지도 — 지금 패널
        return _MapPanelContent(onClose: onClose, isOpen: isOpen);
    }
  }
}

class _IosNowBundle extends StatelessWidget {
  final bool isOpen;
  final bool hasAlert;
  final double panelHeight;
  final double bottomPadding;
  final Animation<double> panelAnim;
  final bool mapReady;
  final VoidCallback onToggle;
  final Widget content;

  const _IosNowBundle({
    required this.isOpen,
    required this.hasAlert,
    required this.panelHeight,
    required this.bottomPadding,
    required this.panelAnim,
    required this.mapReady,
    required this.onToggle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: panelAnim,
      child: _NowPanelSheet(child: content),
      builder: (_, sheet) {
        final capsuleBottom = lerpDouble(
          panelHeight + _kPanelFloat + bottomPadding,
          panelHeight - _kCapsuleHeight + bottomPadding,
          panelAnim.value,
        )!;

        return Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: panelHeight,
              child: sheet!,
            ),
            _PanelScrollIndicator(
                panelHeight: panelHeight, panelAnim: panelAnim),
            Positioned(
              bottom: capsuleBottom,
              left: 0,
              right: 0,
              height: _kCapsuleHeight,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: _NowCapsule(
                    hasAlert: hasAlert,
                    isOpen: isOpen,
                    mapReady: mapReady,
                    buttonStyle: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AndroidNowBundle extends StatelessWidget {
  final bool hasAlert;
  final double panelHeight;
  final Animation<double> panelAnim;
  final bool mapReady;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget content;

  const _AndroidNowBundle({
    required this.hasAlert,
    required this.panelHeight,
    required this.panelAnim,
    required this.mapReady,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final touchWidth = MediaQuery.sizeOf(context).width * 0.80;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: AnimatedBuilder(
        animation: panelAnim,
        child: _NowPanelSheet(child: content),
        builder: (_, sheet) {
          final capsuleBottom = lerpDouble(
            panelHeight + _kPanelFloat,
            panelHeight - _kCapsuleHeight,
            panelAnim.value,
          )!;

          return Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: panelHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: onDragUpdate,
                  onVerticalDragEnd: onDragEnd,
                  child: sheet!,
                ),
              ),
              _PanelScrollIndicator(
                panelHeight: panelHeight,
                panelAnim: panelAnim,
              ),
              Positioned(
                bottom: capsuleBottom,
                left: 0,
                right: 0,
                height: _kCapsuleHeight,
                child: Center(
                  child: SizedBox(
                    width: touchWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: onDragUpdate,
                      onVerticalDragEnd: onDragEnd,
                      child: Align(
                        alignment: Alignment.center,
                        child: _NowCapsule(
                          hasAlert: hasAlert,
                          isOpen: false,
                          mapReady: mapReady,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NowPanelSheet extends StatelessWidget {
  final Widget child;

  const _NowPanelSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Colors.white,
        child: child,
      ),
    );
  }
}

class _PanelScrollIndicator extends StatelessWidget {
  final double panelHeight;
  final Animation<double> panelAnim;

  const _PanelScrollIndicator({
    required this.panelHeight,
    required this.panelAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 6,
      width: 4,
      height: panelHeight - 32,
      child: FadeTransition(
        opacity: panelAnim,
        child: LayoutBuilder(
          builder: (_, constraints) {
            const thumbH = 36.0;
            final trackH = constraints.maxHeight;
            final thumbTop = (1 - panelAnim.value) * (trackH - thumbH);
            return Stack(
              children: [
                Container(
                  width: 4,
                  height: trackH,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  top: thumbTop,
                  child: Container(
                    width: 4,
                    height: thumbH,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 탭별 패널 내용 — 각자 독립적으로 구현
class _MapPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final bool isOpen;
  const _MapPanelContent({required this.onClose, required this.isOpen});

  @override
  ConsumerState<_MapPanelContent> createState() => _MapPanelContentState();
}

class _MapPanelContentState extends ConsumerState<_MapPanelContent> {
  final _shownIds = <String>{};
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime? _lastShake;

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _startShake() {
    if (_accelSub != null) return;
    _accelSub = accelerometerEventStream().listen((event) {
      if (!widget.isOpen) return;
      final mag =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mag > 18) {
        final now = DateTime.now();
        if (_lastShake == null ||
            now.difference(_lastShake!) > const Duration(milliseconds: 1500)) {
          _lastShake = now;
          _onShake();
        }
      }
    });
  }

  void _stopShake() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void _onShake() {
    final now = DateTime.now();
    var candidates = ref
        .read(mapEventsProvider)
        .where((e) => e.endDateTime.isAfter(now))
        .toList();
    if (candidates.isEmpty) return;
    final unseen = candidates.where((e) => !_shownIds.contains(e.id)).toList();
    if (unseen.isEmpty) {
      _shownIds.clear();
    } else {
      candidates = unseen;
    }
    candidates.shuffle();
    final picked = candidates.first;
    _shownIds.add(picked.id);
    HapticFeedback.heavyImpact();
    _tapEvent(picked);
  }

  void _tapEvent(CulturalEvent event) {
    widget.onClose();
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = event;
    ref.read(shellPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final myEvents = (ref
        .watch(partnerMyEventsProvider)
        .where((e) => e.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt)));

    final culturalMap = {
      for (final e in ref.watch(mockPartnerEventStoreProvider)) e.id: e,
    };

    final partnerMode = ref.watch(nowPanelPartnerModeProvider);

    if (myEvents.isEmpty) {
      if (partnerMode) {
        _stopShake();
        return const Center(
          child: Text(
            'Z:GUM 등록된 이벤트가 없습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
          ),
        );
      }
      // Phase 1: 공공 API 이벤트로 채우기
      final publicEvents = ref
          .watch(mapEventsProvider)
          .where((e) =>
              e.source == EventSource.public && e.endDateTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.endDateTime.compareTo(b.endDateTime));
      if (publicEvents.isEmpty) {
        _startShake();
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vibration, size: 32, color: Color(0xFFCCCCCC)),
              SizedBox(height: 12),
              Text(
                '기기를 흔들어보세요',
                style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        );
      }
      _stopShake();
      return _PublicEventList(events: publicEvents, onTap: (e) => _tapEvent(e));
    }
    _stopShake();

    final featured = myEvents.first;
    final featuredCultural = culturalMap[featured.id];
    final rest = myEvents
        .skip(1)
        .where((e) => culturalMap.containsKey(e.id))
        .take(2)
        .toList();

    String timeLeft(PartnerEvent e) {
      final remaining = e.expiresAt.difference(now);
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      return h > 0 ? '$h시간 $m분 남음' : '$m분 남음';
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        // 실제 패널 높이 기준으로 5구역 계산
        final panelH = constraints.maxHeight;
        const topPad = _kCapsuleHeight + 14.0;
        const botPad = 16.0;
        final totalH = panelH - topPad - botPad;
        final sectionH = totalH / 5;
        const itemH = 40.0;
        const itemGap = 8.0;
        final bottomH =
            rest.isNotEmpty ? rest.length * (itemH + itemGap) : sectionH;
        final featuredH = (totalH - bottomH).clamp(sectionH * 2, sectionH * 4);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, topPad, 16, botPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: featuredCultural != null
                    ? () => _tapEvent(featuredCultural)
                    : null,
                child: Container(
                  height: featuredH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              featured.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLeft(featured),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (featured.representativePhotoPath != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: double.infinity,
                              child: Image.file(
                                File(featured.representativePhotoPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(height: 6),
                      Text(
                        featured.venue,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              ...rest.map((e) {
                final cultural = culturalMap[e.id]!;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tapEvent(cultural),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: e.representativePhotoPath != null
                                ? Image.file(
                                    File(e.representativePhotoPath!),
                                    fit: BoxFit.cover,
                                  )
                                : const ColoredBox(color: Color(0xFFE0E0E0)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.venue,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFAAAAAA),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PublicEventList extends StatelessWidget {
  final List<CulturalEvent> events;
  final void Function(CulturalEvent) onTap;

  const _PublicEventList({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, _kCapsuleHeight + 14, 16, 16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = events[i];
        final remaining = e.endDateTime.difference(now);
        final label = remaining.inDays > 0
            ? '${remaining.inDays}일 남음'
            : remaining.inHours > 0
                ? '${remaining.inHours}시간 남음'
                : '${remaining.inMinutes}분 남음';
        return InkWell(
          onTap: () => onTap(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.venue,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFAAAAAA)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _UserPanelContent({required this.onClose});
  @override
  ConsumerState<_UserPanelContent> createState() => _UserPanelContentState();
}

class _UserPanelContentState extends ConsumerState<_UserPanelContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkInProvider.notifier).cleanupExpired();
      _checkPendingRequest();
    });
  }

  Future<void> _checkPendingRequest() async {
    if (!mounted) return;
    final repo = ref.read(friendRepositoryProvider);
    final location = ref.read(userLocationProvider);
    try {
      final requests = await repo.getNearbyRequests(
        myLocation: location,
        myUserId: 'mock_user',
      );
      if (requests.isNotEmpty && mounted) {
        _showAcceptDialog(requests.first);
      }
    } catch (_) {}
  }

  Future<void> _showRequestDialog() async {
    final introShown = await isIeumIntroShown();
    if (!mounted) return;
    if (!introShown) {
      await showIeumIntroPopup(context);
      if (!mounted) return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IeumRequestDialog(
        location: ref.read(userLocationProvider),
        repo: ref.read(friendRepositoryProvider),
      ),
    );
  }

  void _showAcceptDialog(FriendRequest request) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IeumAcceptDialog(
        request: request,
        location: ref.read(userLocationProvider),
        repo: ref.read(friendRepositoryProvider),
      ),
    );
  }

  void _confirmForget(CheckInRecord record) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        content: const Text(
          '정말 잊어도 될까요?',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(checkInProvider.notifier).delete(record.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(checkInProvider);
    final now = DateTime.now();
    final latest = records.isNotEmpty &&
            now.difference(records.first.checkedInAt).inHours < 24
        ? records.first
        : null;
    final friendCount = ref.watch(friendCountProvider);
    final count = friendCount.whenOrNull(data: (v) => v) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 500;
        final traceHeight = compact ? 200.0 : 240.0;
        final bottomPad = 20.0 + MediaQuery.paddingOf(context).bottom;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            _kPanelHandleContentGap,
            20,
            bottomPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 흔적 자리 — 항상 고정 높이
              SizedBox(
                height: traceHeight,
                width: double.infinity,
                child: latest != null
                    ? _RecentTraceCard(record: latest)
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '아직 남긴 흔적이 없습니다',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              if (latest != null)
                Row(
                  children: [
                    _SmallAction(
                      label: '남기기',
                      color: const Color(0xFF1A1A2E),
                      onTap: () {
                        widget.onClose();
                        ref.read(shellPageProvider.notifier).state = 0;
                      },
                    ),
                    const SizedBox(width: 8),
                    _SmallAction(
                      label: '잊기',
                      color: const Color(0xFFAAAAAA),
                      onTap: () => _confirmForget(latest),
                    ),
                  ],
                )
              else
                const SizedBox(height: 32),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFF0F0F0)),
              const SizedBox(height: 14),
              Text(
                '$count명과 이어졌습니다.',
                style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 12),
              // 이음 버튼
              Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  child: GestureDetector(
                    onTap: _showRequestDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '이음',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTraceCard extends StatelessWidget {
  final CheckInRecord record;
  const _RecentTraceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null;
    final dt = record.checkedInAt;
    final dateStr = '${dt.month}.${dt.day.toString().padLeft(2, '0')}';
    final hasMemo = record.memo != null && record.memo!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPhoto)
              Image.file(
                File(record.photoPath!),
                height: constraints.maxHeight,
                fit: BoxFit.fitHeight,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    if (hasMemo) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.memo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallAction(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── 제목 입력 오버레이 바 ────────────────────────────────────────────────────────

class _TitleInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;
  const _TitleInputBar(
      {required this.controller,
      required this.focusNode,
      required this.onClose});

  @override
  State<_TitleInputBar> createState() => _TitleInputBarState();
}

class _TitleInputBarState extends State<_TitleInputBar> {
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: [
        // 빈 공간 탭 시 닫힘
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        // 입력 바
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: Material(
            color: Colors.white,
            elevation: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          decoration: TextDecoration.none),
                      cursorColor: const Color(0xFF16213E),
                      decoration: const InputDecoration(
                        hintText: '이벤트 제목',
                        hintStyle:
                            TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => widget.onClose(),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PartnerPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _PartnerPanelContent({required this.onClose});

  @override
  ConsumerState<_PartnerPanelContent> createState() =>
      _PartnerPanelContentState();
}

class _PartnerPanelContentState extends ConsumerState<_PartnerPanelContent> {
  final _titleCtrl = TextEditingController();
  final _picker = ImagePicker();
  OverlayEntry? _titleOverlay;
  FocusNode? _titleFocusNode;
  OverlayEntry? _descOverlay;
  FocusNode? _descFocusNode;
  final List<File> _photos = [];
  final List<TextEditingController> _photoCtrls = [];
  int _repIndex = 0;
  int _selectedMinutes = 60;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreActiveEvent());
  }

  Future<void> _restoreActiveEvent() async {
    if (!mounted) return;
    if (ref.read(activePartnerEventProvider) != null) return;
    try {
      final service = ref.read(firestorePartnerEventServiceProvider);
      final events = await service.watchByPartner('local-device').first;
      final active = events.where((e) => !e.isExpired).toList();
      if (active.isNotEmpty && mounted) {
        ref.read(activePartnerEventProvider.notifier).state = active.first;
      }
    } catch (e) {
      debugPrint('[PartnerPanel] 활성 이벤트 복원 실패: $e');
    }
  }

  Future<void> _takePhoto() async {
    final shown = await isCameraChooserPopupShown();
    if (!shown && mounted) await showCameraChooserPopup(context);
    if (!mounted) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _photos.add(File(picked.path));
      _photoCtrls.add(TextEditingController());
    });
  }

  void _deletePhoto(int index) {
    setState(() {
      _photoCtrls[index].dispose();
      _photos.removeAt(index);
      _photoCtrls.removeAt(index);
      if (_photos.isEmpty) {
        _repIndex = 0;
      } else if (index == _repIndex) {
        _repIndex = 0;
      } else if (index < _repIndex) {
        _repIndex--;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    if (_photos.isEmpty) return;

    // 19세 이상 여부 확인
    if (!mounted) return;
    final isAdultOnly = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(null),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ZGumDialog(
              heightFactor: 0.30,
              actions: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('전체 이용가',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('19세 이상',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이벤트 대상',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  SizedBox(height: 10),
                  Text('이 이벤트가 19세 이상 대상인가요?',
                      style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    if (isAdultOnly == null || !mounted) return;

    // 무료이용 시작됐는데 알림이 꺼져있으면 등록 시 안내
    final isStarted = await FreeUseService.instance.isStarted();
    if (isStarted) {
      final notifOn = await FreeUseService.instance.isNotificationEnabled();
      if (!notifOn && mounted) {
        await showFreeUseRegisterReminderPopup(context);
        return;
      }
    }

    // 무료이용 일일 한도 체크 (관리자 모드는 항상 통과)
    final isAdmin = ref.read(adminModeProvider);
    final isFreeActive = isAdmin || await FreeUseService.instance.isActive();
    if (!isAdmin && isFreeActive) {
      final canRegister = await FreeUseService.instance.canRegisterToday();
      if (!canRegister) return;
    }

    setState(() => _submitting = true);

    final locationResult = await LocationService().acquireLocation();
    if (!mounted) return;

    final photoList = List.generate(
      _photos.length,
      (i) => PartnerPhoto(
        path: _photos[i].path,
        title: _photoCtrls[i].text.trim().isEmpty
            ? null
            : _photoCtrls[i].text.trim(),
      ),
    );

    final now = DateTime.now();
    final event = PartnerEvent(
      id: now.millisecondsSinceEpoch.toString(),
      partnerId: 'local-device',
      title: title,
      venue: title,
      message: null,
      location: locationResult.position,
      geoHash: 'mock',
      startsAt: now,
      expiresAt: now.add(Duration(minutes: _selectedMinutes)),
      photos: photoList,
      representativeIndex: _repIndex.clamp(0, photoList.length - 1),
      orderId: 'order-${now.millisecondsSinceEpoch}',
      paymentStatus: PaymentStatus.paid,
      isAdultOnly: isAdultOnly,
    );

    if (isFreeActive) await FreeUseService.instance.recordRegistration();

    final paidEvent =
        event.copyWith(paymentStatus: PaymentStatus.paid, paidAt: now);
    _applyToMap(paidEvent);
    // 대기 상태 저장 → 이곳 패널 재오픈 시 대기 뷰로 표시됨
    ref.read(activePartnerEventProvider.notifier).state = paidEvent;
    ref.read(shellPageProvider.notifier).state = 1;
    widget.onClose();
  }

  void _applyToMap(PartnerEvent event) {
    unawaited(ref.read(firestorePartnerEventServiceProvider).save(event));

    final mockCultural = CulturalEvent(
      id: event.id,
      title: event.title,
      venue: event.venue,
      address: '현재 위치',
      description: event.title,
      startDate: event.startsAt,
      endDateTime: event.expiresAt,
      location: event.location,
      category: EventCategory.partner,
      isFree: false,
      source: EventSource.partner,
      partnerMessage: event.message,
    );
    ref.read(mockPartnerEventStoreProvider.notifier).state = [
      ...ref.read(mockPartnerEventStoreProvider),
      mockCultural,
    ];
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = mockCultural;
  }

  void _showDescOverlay(int index) {
    _descOverlay?.remove();
    _descFocusNode?.dispose();
    _descFocusNode = FocusNode();
    final node = _descFocusNode!;
    _descOverlay = OverlayEntry(
      builder: (_) => _TitleInputBar(
        controller: _photoCtrls[index],
        focusNode: node,
        onClose: _closeDescOverlay,
      ),
    );
    Overlay.of(context).insert(_descOverlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _closeDescOverlay() {
    FocusScope.of(context).unfocus();
    _descOverlay?.remove();
    _descOverlay = null;
    setState(() {});
  }

  void _showTitleOverlay() {
    _titleFocusNode?.dispose();
    _titleFocusNode = FocusNode();
    final node = _titleFocusNode!;
    _titleOverlay = OverlayEntry(
      builder: (_) => _TitleInputBar(
        controller: _titleCtrl,
        focusNode: node,
        onClose: _closeTitleOverlay,
      ),
    );
    Overlay.of(context).insert(_titleOverlay!);
    // 오버레이 빌드 완료 후 키보드 요청 — 동시 실행 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _closeTitleOverlay() {
    FocusScope.of(context).unfocus();
    _titleOverlay?.remove();
    _titleOverlay = null;
    setState(() {});
  }

  @override
  void dispose() {
    _titleOverlay?.remove();
    _titleFocusNode?.dispose();
    _descOverlay?.remove();
    _descFocusNode?.dispose();
    _titleCtrl.dispose();
    for (final c in _photoCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvent = ref.watch(activePartnerEventProvider);
    if (activeEvent != null) {
      return _ActiveEventWaitingView(
          event: activeEvent, onClose: widget.onClose);
    }
    final formTopPadding = Platform.isIOS ? 24.0 : _kPanelHandleContentGap;
    final titleToPhotosGap = Platform.isIOS ? 28.0 : 40.0;
    final photosToControlsGap = Platform.isIOS ? 24.0 : 32.0;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          formTopPadding,
          24,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            const Text(
              '제목',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showTitleOverlay,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleCtrl,
                  builder: (_, value, __) => Text(
                    value.text.isEmpty ? '필수' : value.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.text.isEmpty
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: titleToPhotosGap),
            // 사진 3슬롯 (세로 비율 0.85로 확대)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                      child: AspectRatio(
                          aspectRatio: 0.85, child: _buildPhotoCell(i))),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: i < _photos.length
                        ? _buildDescField(i)
                        : const SizedBox(height: 32),
                  ),
                ],
              ],
            ),
            SizedBox(height: photosToControlsGap),
            // 노출시간
            Row(
              children: [
                const Text(
                  '노출시간',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555)),
                ),
                const SizedBox(width: 12),
                ...[60, 120, 180].map((min) {
                  final selected = _selectedMinutes == min;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = min),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF16213E)
                              : const Color(0xFFF4F4F7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${min ~/ 60}시간',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            // 등록 버튼 — 무료이용 기간 중 "무료이용"으로 표기, 한도 소진 시 비활성화
            Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.5,
                child: FutureBuilder<(bool, bool)>(
                  future: () async {
                    final isAdmin = ref.read(adminModeProvider);
                    if (isAdmin) return (true, true);
                    final active = await FreeUseService.instance.isActive();
                    final canRegister = active
                        ? await FreeUseService.instance.canRegisterToday()
                        : true;
                    return (active, canRegister);
                  }(),
                  builder: (context, snapshot) {
                    final isFree = snapshot.data?.$1 == true;
                    final canRegister = snapshot.data?.$2 != false;
                    final disabled = _submitting || !canRegister;
                    return GestureDetector(
                      onTap: disabled ? null : _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: disabled
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isFree ? '무료이용' : '등록',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCell(int i) {
    if (i < _photos.length) {
      final isRep = i == _repIndex;
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_photos[i], fit: BoxFit.cover),
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: () => setState(() => _repIndex = i),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isRep
                        ? const Color(0xFF16213E)
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isRep ? Icons.star : Icons.star_border,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (i == _photos.length && _photos.length < 3) {
      return GestureDetector(
        onTap: _takePhoto,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_a_photo_outlined,
                    size: 20, color: Color(0xFFAAAAAA)),
                if (i == 0) ...[
                  const SizedBox(height: 4),
                  const Text('필수',
                      style: TextStyle(fontSize: 11, color: Color(0xFFCC3333))),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildDescField(int i) {
    return GestureDetector(
      onTap: () => _showDescOverlay(i),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _photoCtrls[i],
          builder: (_, value, __) => Text(
            value.text.isEmpty ? '내용' : value.text,
            style: TextStyle(
              fontSize: 11,
              color: value.text.isEmpty
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ActiveEventWaitingView extends ConsumerStatefulWidget {
  final PartnerEvent event;
  final VoidCallback onClose;
  const _ActiveEventWaitingView({required this.event, required this.onClose});

  @override
  ConsumerState<_ActiveEventWaitingView> createState() =>
      _ActiveEventWaitingViewState();
}

class _ActiveEventWaitingViewState
    extends ConsumerState<_ActiveEventWaitingView> {
  Timer? _timer;
  late Duration _remaining;
  bool _extending = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateRemaining);
      if (_remaining <= Duration.zero) _finish();
    });
  }

  void _updateRemaining() {
    final diff = widget.event.expiresAt.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  bool _withinRefundThreshold() {
    final total = widget.event.expiresAt.difference(widget.event.startsAt);
    final elapsed = DateTime.now().difference(widget.event.startsAt);
    final thresholdSeconds = total.inSeconds ~/ 6;
    return elapsed.inSeconds < thresholdSeconds;
  }

  void _showExtendConfirm() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66000000),
      builder: (_) => Center(
        child: ZGumDialog(
          heightFactor: 0.38,
          centerContent: true,
          actions: ZGumButton(
            label: '확인',
            onTap: () {
              Navigator.of(context).pop();
              _extend();
            },
          ),
          child: const Text(
            '1회 1시간 연장가능',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ),
    );
  }

  void _showTerminateConfirm() {
    final hours =
        widget.event.expiresAt.difference(widget.event.startsAt).inHours;
    final withinThreshold = _withinRefundThreshold();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66000000),
      builder: (_) => Center(
        child: ZGumDialog(
          heightFactor: 0.38,
          centerContent: true,
          actions: ZGumButton(
            label: '확인',
            onTap: () {
              Navigator.of(context).pop();
              _terminate();
            },
          ),
          child: withinThreshold
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '시간이 남아있습니다.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$hours시간 재등록 1회 가능',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                )
              : Text(
                  '${_formatDuration(_remaining)} 남아있습니다.\n종료하시겠습니까?',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
        ),
      ),
    );
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    unawaited(
        ref.read(firestorePartnerEventServiceProvider).expire(widget.event.id));
    // 지도에서 제거
    final store = ref.read(mockPartnerEventStoreProvider);
    ref.read(mockPartnerEventStoreProvider.notifier).state =
        store.where((e) => e.id != widget.event.id).toList();
    // 그리드에 추가
    final list = ref.read(partnerMyEventsProvider);
    ref.read(partnerMyEventsProvider.notifier).state = [widget.event, ...list];
    ref.read(activePartnerEventProvider.notifier).state = null;
    widget.onClose();
  }

  void _terminate() {
    _timer?.cancel();
    _timer = null;
    unawaited(
        ref.read(firestorePartnerEventServiceProvider).expire(widget.event.id));
    // 지도에서 제거, 그리드에는 저장하지 않음
    final store = ref.read(mockPartnerEventStoreProvider);
    ref.read(mockPartnerEventStoreProvider.notifier).state =
        store.where((e) => e.id != widget.event.id).toList();
    ref.read(activePartnerEventProvider.notifier).state = null;
    widget.onClose();
  }

  Future<void> _extend() async {
    if (_extending) return;
    setState(() => _extending = true);
    try {
      final isAdmin = ref.read(adminModeProvider);
      final isFreeActive = isAdmin || await FreeUseService.instance.isActive();
      if (!isAdmin && isFreeActive) {
        final canRegister = await FreeUseService.instance.canRegisterToday();
        if (!canRegister) return;
      }
      if (isFreeActive) await FreeUseService.instance.recordRegistration();

      final newExpiresAt = widget.event.expiresAt.add(const Duration(hours: 1));
      await ref
          .read(firestorePartnerEventServiceProvider)
          .extend(widget.event.id, newExpiresAt);
      final extendedEvent = widget.event.copyWith(expiresAt: newExpiresAt);
      ref.read(activePartnerEventProvider.notifier).state = extendedEvent;

      final store = ref.read(mockPartnerEventStoreProvider);
      ref.read(mockPartnerEventStoreProvider.notifier).state = store.map((e) {
        if (e.id != widget.event.id) return e;
        return CulturalEvent(
          id: e.id,
          title: e.title,
          venue: e.venue,
          address: e.address,
          description: e.description,
          startDate: e.startDate,
          endDateTime: newExpiresAt,
          location: e.location,
          category: e.category,
          isFree: e.isFree,
          source: e.source,
          partnerMessage: e.partnerMessage,
          isAdultOnly: e.isAdultOnly,
        );
      }).toList();
    } finally {
      if (mounted) setState(() => _extending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining <= Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            '이벤트 진행 중',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const Spacer(),
          Text(
            isExpired ? '종료됨' : _formatDuration(_remaining),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              color:
                  isExpired ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A2E),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isExpired ? '' : '남은 시간',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
          const Spacer(),
          if (isExpired)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                '종료 완료',
                style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _extending ? null : _showExtendConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _extending
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '연장',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTerminateConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '종료',
                        style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NowCapsule extends StatefulWidget {
  final bool hasAlert;
  final bool isOpen;
  final bool mapReady;
  final bool buttonStyle;

  const _NowCapsule({
    required this.hasAlert,
    required this.isOpen,
    required this.mapReady,
    this.buttonStyle = false,
  });

  @override
  State<_NowCapsule> createState() => _NowCapsuleState();
}

class _NowCapsuleState extends State<_NowCapsule>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _blinkAnim;
  late final AnimationController _light;
  late final Animation<double> _lightAnim;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _blinkAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
    );
    if (widget.hasAlert) _blink.repeat(reverse: true);

    // State 재생성 시 이미 완료 상태로 시작해 재실행 방지
    _light = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      value: widget.mapReady ? 1.0 : 0.0,
    );
    _lightAnim = CurvedAnimation(parent: _light, curve: Curves.decelerate);

    if (widget.mapReady && !_light.isCompleted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _light.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _NowCapsule old) {
    super.didUpdateWidget(old);
    if (widget.mapReady && !old.mapReady && !_light.isCompleted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _light.forward();
      });
    }
    if (widget.hasAlert && !old.hasAlert) {
      _blink.repeat(reverse: true);
    } else if (!widget.hasAlert && old.hasAlert) {
      _blink
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capsuleWidth = MediaQuery.sizeOf(context).width * 0.50;
    const normalColor = Color(0xFF16213E);
    const alertColor = Color(0xFF2D6BE4);

    return AnimatedBuilder(
      animation: Listenable.merge([_blinkAnim, _lightAnim]),
      builder: (_, __) {
        final color = widget.hasAlert ? alertColor : normalColor;
        final blinkOpacity = widget.hasAlert ? _blinkAnim.value : 1.0;
        final progress = _lightAnim.value;
        final halfW = capsuleWidth / 2;

        // 양쪽 끝에서 중앙으로 채우기 (decelerate: 끝에서 빠르게 출발 → 중앙에서 부드럽게 안착)
        final fillWidth = progress * halfW;

        if (widget.buttonStyle) {
          return Container(
            width: 84,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: blinkOpacity * 0.88),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.isOpen
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            width: capsuleWidth,
            height: 6,
            child: progress >= 1.0
                ? ColoredBox(
                    color: color.withValues(alpha: blinkOpacity * 0.70))
                : Stack(
                    children: [
                      // 좌측 끝 → 중앙으로
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: ColoredBox(
                            color:
                                color.withValues(alpha: blinkOpacity * 0.70)),
                      ),
                      // 우측 끝 → 중앙으로
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: ColoredBox(
                            color:
                                color.withValues(alpha: blinkOpacity * 0.70)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
