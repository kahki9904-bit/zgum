import 'dart:io';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/partner_focus_provider.dart';
import '../../core/providers/shell_page_provider.dart';
import '../../core/providers/user_location_provider.dart';
import '../../core/shell_gesture_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../features/friend/providers/friend_provider.dart';
import '../../features/friend/services/friend_proximity_service.dart';
import '../../features/map_room/screens/map_room_screen.dart';
import '../../features/partner_room/screens/partner_room_screen.dart';
import '../../features/user_room/screens/user_room_screen.dart';
import '../../services/gesture_exclusion_service.dart';
import '../../promotions/free_use/free_use_service.dart';
import '../widgets/popups/once/ieum_intro_popup.dart';
import '../widgets/popups/once/map_marker_intro_popup.dart';
import '../widgets/popups/once/partner_intro_popup.dart';
import 'shell_constants.dart';
import 'panels/map_panel_content.dart';

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
  // ValueNotifier: 패널 열림 상태 변경이 PageView rebuild를 유발하지 않도록 분리
  final _nowPanelOpen = ValueNotifier<bool>(false);
  // AnimationController: Transform.translate 기반 — 레이아웃 변경 없이 페인트만 이동
  late final AnimationController _panelAnim;
  double panelHeight = 300.0;
  bool _tabVisible = false;
  bool _showNowTab = false;
  bool _mapReady = false;
  bool _mapMarkerIntroRequested = false;

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
    _showMapMarkerIntroAfterReady();
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

  Future<void> _showMapMarkerIntroAfterReady() async {
    if (_mapMarkerIntroRequested) return;
    _mapMarkerIntroRequested = true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final shown = await isMapMarkerIntroShown();
    if (!shown && mounted && _page == 1) {
      await showMapMarkerIntroPopup(context);
    }
  }

  Future<void> _runFriendTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final location = ref.read(userLocationProvider);
    final repo = ref.read(friendRepositoryProvider);
    final service = FriendProximityService(repo);
    await FriendProximityService.recordPresence(uid, location);
    await service.checkAndRenewNearbyFriends(
      myUserId: uid,
      myLocation: location,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runFriendTasks();
    }
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
      _runFriendTasks();
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
    if (page == 0 && _nowPanelOpen.value) _closeNow();
    _pc.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncExclusionRects();
      _recenterMapOnReturn(page);
    });
  }

  void _recenterMapOnReturn(int page) {
    if (page != 1 || ref.read(partnerFocusPendingProvider)) return;
    final state = _mapKey.currentState;
    if (state?.isNavigating == true) return;
    state?.recenterOnUser();
  }

  void _syncExclusionRects() {
    if (!mounted) return;
    if (_page != 1) {
      GestureExclusionService.clearExclusionRects();
      return;
    }
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = ShellGestureLayoutSpec.current.androidBackExclusionWidth;
    if (w <= 0) {
      GestureExclusionService.clearExclusionRects();
      return;
    }
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
    if (_page == 0 || _page == 2) return;
    if (_nowPanelOpen.value) {
      _closeNow();
    } else {
      _nowPanelOpen.value = true;
      final rem = 1.0 - _panelAnim.value;
      _panelAnim.animateTo(1.0,
          duration: Duration(milliseconds: (rem * 300).round().clamp(80, 300)),
          curve: Curves.easeOut);
    }
  }

  void _onNowDragUpdate(DragUpdateDetails d) {
    final maxDist = panelHeight + kShellPanelFloat;
    _panelAnim.value =
        (_panelAnim.value - (d.primaryDelta ?? 0) / maxDist).clamp(0.0, 1.0);
  }

  void _onNowDragEnd(DragEndDetails d) {
    if (_page == 0) return;
    final vel = d.primaryVelocity ?? 0;
    if (vel < -300 || (_panelAnim.value >= 0.4 && vel < 300)) {
      _nowPanelOpen.value = true;
      final rem = 1.0 - _panelAnim.value;
      _panelAnim.animateTo(1.0,
          duration: Duration(milliseconds: (rem * 300).round().clamp(80, 300)),
          curve: Curves.easeOut);
    } else {
      _nowPanelOpen.value = false;
      final rem = _panelAnim.value;
      _panelAnim.animateTo(0.0,
          duration: Duration(milliseconds: (rem * 280).round().clamp(80, 280)),
          curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // shellPageProvider 변화 감지 → 페이지 이동
    ref.listen<int>(shellPageProvider, (prev, next) {
      if (prev != next) _goTo(next);
    });

    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    panelHeight = (availableHeight * 0.68).clamp(420.0, 560.0);
    final gesture = ShellGestureLayoutSpec.current;
    final bottomPadding = max(media.padding.bottom, gesture.bottomPaddingMin) +
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _syncExclusionRects();
                  _recenterMapOnReturn(p);
                });
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
                opacity: (_showNowTab && _page == 1) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showNowTab || _page != 1,
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
                                panelHeight: panelHeight,
                                bottomPadding: bottomPadding,
                                onToggle: _toggleNow,
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
          final gesture = ShellGestureLayoutSpec.current;
          final dx = e.position.dx - _startX!;
          final dy = (e.position.dy - _startY!).abs();
          if (dx.abs() < gesture.pageSwipeDistance ||
              dx.abs() < dy * gesture.pageSwipeAxisRatio) {
            return;
          }
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

    if (Platform.isIOS) {
      return _IosNowBundle(
        isOpen: isOpen,
        panelHeight: panelHeight,
        bottomPadding: bottomPadding,
        panelAnim: panelAnim,
        mapReady: mapReady,
        onToggle: onToggle!,
        content: content,
      );
    }

    return _AndroidNowBundle(
      isOpen: isOpen,
      panelHeight: panelHeight,
      bottomPadding: bottomPadding,
      panelAnim: panelAnim,
      mapReady: mapReady,
      onToggle: onToggle,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      content: content,
    );
  }

  Widget _buildPanelContent() {
    return MapPanelContent(onClose: onClose, isOpen: isOpen);
  }
}

class _IosNowBundle extends StatelessWidget {
  final bool isOpen;
  final double panelHeight;
  final double bottomPadding;
  final Animation<double> panelAnim;
  final bool mapReady;
  final VoidCallback onToggle;
  final Widget content;

  const _IosNowBundle({
    required this.isOpen,
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
  final bool isOpen;
  final double panelHeight;
  final double bottomPadding;
  final Animation<double> panelAnim;
  final bool mapReady;
  final VoidCallback? onToggle;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget content;

  const _AndroidNowBundle({
    required this.isOpen,
    required this.panelHeight,
    required this.bottomPadding,
    required this.panelAnim,
    required this.mapReady,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.content,
    this.onToggle,
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
                      onTap: onToggle,
                      onVerticalDragUpdate: onDragUpdate,
                      onVerticalDragEnd: onDragEnd,
                      child: Align(
                        alignment: Alignment.center,
                        child: _NowCapsule(
                          isOpen: isOpen,
                          mapReady: mapReady,
                          buttonStyle: true,
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
                      color: AppColors.actionGold.withValues(alpha: 0.22),
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
  final bool isOpen;
  final bool mapReady;
  final bool buttonStyle;

  const _NowCapsule({
    required this.isOpen,
    required this.mapReady,
    this.buttonStyle = false,
  });

  @override
  State<_NowCapsule> createState() => _NowCapsuleState();
}

class _NowCapsuleState extends State<_NowCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light;
  late final Animation<double> _lightAnim;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capsuleWidth = MediaQuery.sizeOf(context).width * 0.50;
    const color = AppColors.actionGoldBright;

    return AnimatedBuilder(
      animation: _lightAnim,
      builder: (_, __) {
        final progress = _lightAnim.value;
        final halfW = capsuleWidth / 2;

        // 양쪽 끝에서 중앙으로 채우기 (decelerate: 끝에서 빠르게 출발 → 중앙에서 부드럽게 안착)
        final fillWidth = progress * halfW;

        if (widget.buttonStyle) {
          return Container(
            width: 84,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.88),
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
                ? ColoredBox(color: color.withValues(alpha: 0.70))
                : Stack(
                    children: [
                      // 좌측 끝 → 중앙으로
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: ColoredBox(color: color.withValues(alpha: 0.70)),
                      ),
                      // 우측 끝 → 중앙으로
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: ColoredBox(color: color.withValues(alpha: 0.70)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
