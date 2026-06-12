import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/partner_focus_provider.dart';
import 'core/providers/shell_page_provider.dart';
import 'core/providers/free_use_provider.dart';
import 'core/services/free_use_service.dart';
import 'features/alert/models/partner_event.dart';
import 'features/alert/providers/alert_provider.dart';
import 'features/alert/providers/geofence_provider.dart';
import 'features/map_room/screens/map_room_screen.dart';
import 'features/partner_room/screens/partner_room_screen.dart';
import 'features/user_room/screens/user_room_screen.dart';
import 'presentation/widgets/free_use_expiry_popup.dart';
import 'presentation/widgets/free_use_intro_popup.dart';
import 'presentation/widgets/trace_checkin_dialog.dart';
import 'services/gesture_exclusion_service.dart';

// 지금 패널/캡슐 크기 상수 (file-level — _NowBundle에서도 사용)
const double _kPanelHeight = 300.0;
const double _kCapsuleHeight = 40.0;
const double _kPanelFloat = 30.0;

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with TickerProviderStateMixin {
  final _pc = PageController(initialPage: 1);
  final _mapKey = GlobalKey<MapRoomScreenState>();
  int _page = 1;
  bool _tracePopupShowing = false;
  // ValueNotifier: 패널 열림 상태 변경이 PageView rebuild를 유발하지 않도록 분리
  final _nowPanelOpen = ValueNotifier<bool>(false);
  // AnimationController: Transform.translate 기반 — 레이아웃 변경 없이 페인트만 이동
  late final AnimationController _panelAnim;
  late final Animation<double> _panelSlide;
  bool _tabVisible = false;
  bool _showNowTab = false;

  void _onRouteAnimationComplete() {
    setState(() => _tabVisible = true);
    // 지도(WebView) 초기화 완료 후 패널 표시 — 1000ms 대기
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showNowTab = true);
    });
  }

  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlide =
        CurvedAnimation(parent: _panelAnim, curve: Curves.easeInOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      await FreeUseService.instance.initialize();
      if (!mounted) return;
      if (FreeUseService.instance.shouldShowIntroPopup) {
        await showFreeUseIntroPopup(
          context,
          onActivated: () =>
              ref.read(freeUseProvider.notifier).activateFreeUse(),
        );
      } else if (FreeUseService.instance.shouldShowExpiryWarning) {
        await showFreeUseExpiryPopup(context);
      }
    });
  }

  @override
  void dispose() {
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

  void _openNow() {
    if (!_nowPanelOpen.value) {
      _nowPanelOpen.value = true;
      _panelAnim.forward();
    }
  }

  void _closeNow() {
    if (_nowPanelOpen.value) {
      _nowPanelOpen.value = false;
      _panelAnim.reverse();
    }
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: _page == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(1);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pc,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) {
                setState(() => _page = p);
                // 수동 스와이프로 인한 페이지 변경을 shellPageProvider에 반영
                // _applyToMap 등이 나중에 page=1을 설정할 때 변경 감지가 가능해짐
                ref.read(shellPageProvider.notifier).state = p;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _syncExclusionRects());
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
                              bottom: bottomPadding + _kPanelHeight + _kCapsuleHeight + _kPanelFloat,
                              child: GestureDetector(
                                onTap: _closeNow,
                                onVerticalDragEnd: (d) {
                                  if ((d.primaryVelocity ?? 0) > 200) {
                                    _closeNow();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                              ),
                            ),

                          // Transform.translate: 레이아웃 고정, 페인트만 이동
                          // AnimatedPositioned와 달리 매 프레임 상위 Stack re-layout 없음
                          // → PageView/지도 WebView가 애니메이션에 반응하지 않음
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: bottomPadding,
                            height: _kPanelHeight + _kCapsuleHeight + _kPanelFloat,
                            child: AnimatedBuilder(
                              animation: _panelSlide,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  (1.0 - _panelSlide.value) * (_kPanelHeight + _kPanelFloat),
                                ),
                                child: child,
                              ),
                              child: _NowBundle(
                                isOpen: isOpen,
                                hasAlert: hasAlert,
                                onToggle: isOpen ? _closeNow : _openNow,
                                onOpen: _openNow,
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


// ── "지금" 캡슐+패널 묶음 ────────────────────────────────────────────────────────
// Stack 구조: 패널(하단) + 캡슐 손잡이(패널 위)
// AnimatedPositioned로 통째로 슬라이드 — 닫힘 시 캡슐만 노출, 열림 시 전체 노출

class _NowBundle extends StatefulWidget {
  final bool isOpen;
  final bool hasAlert;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _NowBundle({
    required this.isOpen,
    required this.hasAlert,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  State<_NowBundle> createState() => _NowBundleState();
}

class _NowBundleState extends State<_NowBundle> {
  // 캡슐 제스처
  final Set<int> _capActive = {};
  bool _capMulti = false;
  Offset? _capsuleStart;

  // 패널 본체 제스처 (열린 상태: 아래로 내리기)
  final Set<int> _panActive = {};
  bool _panMulti = false;
  Offset? _panelStart;

  void _handlePanelPointerDown(PointerDownEvent e) {
    if (!widget.isOpen) return;
    _panActive.add(e.pointer);
    if (_panActive.length >= 2 || _panMulti) {
      _panMulti = true;
      _panelStart = null;
      return;
    }
    _panelStart = e.localPosition;
  }

  void _handlePanelPointerMove(PointerMoveEvent e) {
    if (_panMulti || _panelStart == null || !widget.isOpen) return;
    final dy = e.localPosition.dy - _panelStart!.dy;
    final dx = (e.localPosition.dx - _panelStart!.dx).abs();
    if (dy > 25 && dy > dx) {
      _panelStart = null;
      widget.onToggle();
    }
  }

  void _handlePanelPointerUp(PointerUpEvent e) {
    _panActive.remove(e.pointer);
    if (_panActive.isEmpty) _panMulti = false;
    _panelStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final touchWidth = screenWidth * 0.80;

    return Stack(
      children: [
        // 패널 본체 — 열린 상태에서 아래로 쓸면 닫기
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: _kPanelHeight,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePanelPointerDown,
            onPointerMove: _handlePanelPointerMove,
            onPointerUp: _handlePanelPointerUp,
            onPointerCancel: (e) {
              _panActive.remove(e.pointer);
              if (_panActive.isEmpty) _panMulti = false;
              _panelStart = null;
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 캡슐 손잡이 — 닫힌 상태: 위로 30px 드래그 → 열기 / 열린 상태: 아래로 25px → 닫기
        Positioned(
          bottom: _kPanelHeight + _kPanelFloat,
          left: 0,
          right: 0,
          height: _kCapsuleHeight,
          child: Center(
            child: SizedBox(
              width: touchWidth,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  _capActive.add(e.pointer);
                  if (_capActive.length >= 2 || _capMulti) {
                    _capMulti = true;
                    _capsuleStart = null;
                    return;
                  }
                  _capsuleStart = e.localPosition;
                },
                onPointerMove: (e) {
                  if (_capMulti || _capsuleStart == null) return;
                  final dy = e.localPosition.dy - _capsuleStart!.dy;
                  final dx = (e.localPosition.dx - _capsuleStart!.dx).abs();
                  if (!widget.isOpen && dy < -30 && dy.abs() > dx) {
                    _capsuleStart = null;
                    widget.onOpen();
                    return;
                  }
                  if (widget.isOpen && dy > 25 && dy > dx) {
                    _capsuleStart = null;
                    widget.onToggle();
                  }
                },
                onPointerUp: (e) {
                  _capActive.remove(e.pointer);
                  if (_capActive.isEmpty) _capMulti = false;
                  _capsuleStart = null;
                },
                onPointerCancel: (e) {
                  _capActive.remove(e.pointer);
                  if (_capActive.isEmpty) _capMulti = false;
                  _capsuleStart = null;
                },
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: _NowCapsule(hasAlert: widget.hasAlert, isOpen: widget.isOpen),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NowCapsule extends StatefulWidget {
  final bool hasAlert;
  final bool isOpen;

  const _NowCapsule({required this.hasAlert, required this.isOpen});

  @override
  State<_NowCapsule> createState() => _NowCapsuleState();
}

class _NowCapsuleState extends State<_NowCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _blinkAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
    );
    if (widget.hasAlert) _blink.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NowCapsule old) {
    super.didUpdateWidget(old);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capsuleWidth = MediaQuery.sizeOf(context).width * 0.50;
    const normalColor = Color(0xFF16213E);
    const alertColor = Color(0xFF2D6BE4);

    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (_, __) {
        final color = widget.hasAlert ? alertColor : normalColor;
        final opacity = widget.hasAlert ? _blinkAnim.value : 1.0;
        return Container(
          width: capsuleWidth,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              height: 14,
              width: capsuleWidth * 0.7,
              child: CustomPaint(
                painter: _ChevronPainter(isOpen: widget.isOpen),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final bool isOpen;
  const _ChevronPainter({required this.isOpen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final spread = size.width * 0.45;
    const depth = 5.0;

    if (isOpen) {
      canvas.drawLine(Offset(cx - spread, cy - depth / 2), Offset(cx, cy + depth / 2), paint);
      canvas.drawLine(Offset(cx, cy + depth / 2), Offset(cx + spread, cy - depth / 2), paint);
    } else {
      canvas.drawLine(Offset(cx - spread, cy + depth / 2), Offset(cx, cy - depth / 2), paint);
      canvas.drawLine(Offset(cx, cy - depth / 2), Offset(cx + spread, cy + depth / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.isOpen != isOpen;
}
