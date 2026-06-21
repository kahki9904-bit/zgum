import 'dart:io';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/partner_focus_provider.dart';
import '../../core/providers/shell_page_provider.dart';
import '../../core/providers/partner_my_events_provider.dart';
import '../../data/models/cultural_event.dart';
import '../../dev/mock_partner_event_store.dart';
import '../../features/alert/models/partner_event.dart';
import '../../features/alert/providers/alert_provider.dart';
import '../../features/alert/providers/geofence_provider.dart';
import '../../features/map_room/screens/map_room_screen.dart';
import '../../features/partner_room/screens/partner_room_screen.dart';
import '../../features/user_room/screens/user_room_screen.dart';
import '../widgets/trace_checkin_dialog.dart';
import '../../services/gesture_exclusion_service.dart';
import '../../core/providers/active_partner_event_provider.dart';
import '../../promotions/free_use/free_use_service.dart';
import '../widgets/popups/once/ieum_intro_popup.dart';
import '../widgets/popups/once/partner_intro_popup.dart';
import '../../services/firestore_partner_event_service.dart';
import '../../services/device_id_service.dart';
import 'shell_constants.dart';
import 'panels/alert_panel_content.dart';
import 'panels/user_panel_content.dart';
import 'panels/map_panel_content.dart';
import 'panels/partner_panel_content.dart';


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
  bool _alertReady = false;
  // ValueNotifier: 패널 열림 상태 변경이 PageView rebuild를 유발하지 않도록 분리
  final _nowPanelOpen = ValueNotifier<bool>(false);
  // AnimationController: Transform.translate 기반 — 레이아웃 변경 없이 페인트만 이동
  late final AnimationController _panelAnim;
  double panelHeight = 300.0;
  bool _tabVisible = false;
  bool _showNowTab = false;
  bool _mapReady = false;
  PartnerEvent? _pendingAlert;

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

  Future<void> _showIntroIfNeeded() async {
    await FreeUseService.instance.startOnFirstLaunch();
  }

  Future<void> _showIeumIntroIfNeeded() async {
    final shown = await isIeumIntroShown();
    if (!shown && mounted) await showIeumIntroPopup(context);
  }

  Future<void> _showPartnerIntroIfNeeded() async {
    final shown = await isPartnerIntroShown();
    if (!shown && mounted) await showPartnerIntroPopup(context);
  }

// 앱 시작 시 내 이벤트 복원 후 캡슐 알림 활성화 (복원 전 깜박임 방지)
  Future<void> _initAlertReady() async {
    try {
      final deviceId = await DeviceIdService.getId();
      final service = ref.read(firestorePartnerEventServiceProvider);
      final events = await service.watchByPartner(deviceId).first;
      final active = events.where((e) => !e.isExpired).toList();
      if (active.isNotEmpty && mounted) {
        ref.read(activePartnerEventProvider.notifier).state = active.first;
      }
    } catch (_) {}
    if (mounted) setState(() => _alertReady = true);
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initAlertReady();
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
    if (_pendingAlert != null) {
      ref.read(partnerAlertProvider.notifier).markAsSeen(_pendingAlert!.id);
      setState(() => _pendingAlert = null);
    }
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
      _updatePendingAlert();
    }
  }

  // 패널이 열릴 때 한 번만 호출 — 파트너 탭(2)은 작업 중일 수 있으므로 차단
  void _updatePendingAlert() {
    if (_page == 2 && ref.read(activePartnerEventProvider) != null) return;
    // 내가 등록한 이벤트는 알림에서 제외
    final myEventIds = ref.read(partnerMyEventsProvider).map((e) => e.id).toSet();
    final activeEvent = ref.read(activePartnerEventProvider);
    if (activeEvent != null) myEventIds.add(activeEvent.id);
    final alerts = (ref.read(partnerAlertProvider)
        .where((e) => !e.seen && !e.isExpired && !myEventIds.contains(e.id))
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt)));
    if (alerts.isEmpty) return;
    setState(() => _pendingAlert = alerts.first);
  }

  // 사용자가 알림 카드를 탭했을 때 — 지도로 이동 후 패널 닫기
  void _confirmAlert(PartnerEvent alert) {
    final cultural = CulturalEvent(
      id: alert.id,
      title: alert.title,
      venue: alert.venue,
      address: '현재 위치',
      description: alert.title,
      startDate: alert.startsAt,
      endDateTime: alert.expiresAt,
      location: alert.location,
      category: EventCategory.partner,
      isFree: false,
      source: EventSource.partner,
      partnerMessage: alert.message,
    );
    final store = ref.read(mockPartnerEventStoreProvider);
    if (!store.any((e) => e.id == cultural.id)) {
      ref.read(mockPartnerEventStoreProvider.notifier).state = [...store, cultural];
    }
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = cultural;
    ref.read(partnerAlertProvider.notifier).markAsSeen(alert.id);
    _goTo(1);
    _closeNow();
  }

  void _onNowDragUpdate(DragUpdateDetails d) {
    final maxDist = panelHeight + kShellPanelFloat;
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
      _updatePendingAlert();
    } else {
      _nowPanelOpen.value = false;
      final rem = _panelAnim.value;
      _panelAnim.animateTo(0.0,
          duration: Duration(milliseconds: (rem * 280).round().clamp(80, 280)),
          curve: Curves.easeIn);
    }
  }

  /// 지오펜스 3분 체류 달성 시 자동으로 흔적 팝업 표시
  void _showTracePopup(PartnerEvent event) {
    if (_tracePopupShowing || !mounted) return;
    final myEventIds = ref.read(partnerMyEventsProvider).map((e) => e.id).toSet();
    final activeEvent = ref.read(activePartnerEventProvider);
    if (activeEvent != null) myEventIds.add(activeEvent.id);
    if (myEventIds.contains(event.id)) return;
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

    final hasAlert = ref.watch(hasUnseenAlertProvider) && _alertReady;
    final activePartnerEvent = ref.watch(activePartnerEventProvider);
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    panelHeight = (availableHeight * 0.68).clamp(420.0, 560.0);
    final bottomPadding =
        max(media.padding.bottom, Platform.isAndroid ? 16.0 : 0.0) +
            kShellIosGestureBuffer;

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
                if (p == 0) _showIeumIntroIfNeeded();
                if (p == 2) _showPartnerIntroIfNeeded();
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
                            bottom: 0,
                            height: panelHeight +
                                kShellCapsuleHeight +
                                kShellPanelFloat +
                                bottomPadding,
                            child: AnimatedBuilder(
                              animation: _panelAnim,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  (1.0 - _panelAnim.value) *
                                      (panelHeight + kShellPanelFloat),
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
                                isPartnerBusy: activePartnerEvent != null,
                                onDragUpdate: _onNowDragUpdate,
                                onDragEnd: _onNowDragEnd,
                                onClose: _closeNow,
                                pendingAlert: _pendingAlert,
                                onAlertConfirm: _confirmAlert,
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
  final bool isPartnerBusy;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onClose;
  final PartnerEvent? pendingAlert;
  final void Function(PartnerEvent)? onAlertConfirm;

  const _NowBundle({
    required this.isOpen,
    required this.hasAlert,
    required this.panelHeight,
    required this.bottomPadding,
    required this.panelAnim,
    required this.currentPage,
    required this.mapReady,
    required this.isPartnerBusy,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onClose,
    this.onToggle,
    this.pendingAlert,
    this.onAlertConfirm,
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
      bottomPadding: bottomPadding,
      panelAnim: panelAnim,
      mapReady: mapReady,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      content: content,
    );
  }

  Widget _buildPanelContent() {
    // 파트너 탭(2)은 이벤트 진행 중일 때만 알림 끼어들기 차단 (등록 안 한 상태에서는 알림 표시)
    if (pendingAlert != null && !(currentPage == 2 && isPartnerBusy)) {
      return AlertPanelContent(
        alert: pendingAlert!,
        onTap: () => onAlertConfirm?.call(pendingAlert!),
        onClose: onClose,
      );
    }
    switch (currentPage) {
      case 2:
        if (!isOpen) return const SizedBox.shrink();
        return PartnerPanelContent(onClose: onClose);
      case 0:
        return UserPanelContent(onClose: onClose);
      default:
        return MapPanelContent(onClose: onClose, isOpen: isOpen);
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
          panelHeight + kShellPanelFloat + bottomPadding,
          panelHeight - kShellCapsuleHeight + bottomPadding,
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
              height: kShellCapsuleHeight,
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
  final double bottomPadding;
  final Animation<double> panelAnim;
  final bool mapReady;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget content;

  const _AndroidNowBundle({
    required this.hasAlert,
    required this.panelHeight,
    required this.bottomPadding,
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
            panelHeight + kShellPanelFloat,
            panelHeight - kShellCapsuleHeight,
            panelAnim.value,
          )!;

          return Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: panelHeight + bottomPadding,
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
                height: kShellCapsuleHeight,
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
        vsync: this, duration: const Duration(milliseconds: 400));
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