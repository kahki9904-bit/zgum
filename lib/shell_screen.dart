import 'package:flutter/material.dart';
import 'features/map_room/screens/map_room_screen.dart';
import 'features/partner_room/screens/partner_room_screen.dart';
import 'features/user_room/screens/user_room_screen.dart';
import 'services/gesture_exclusion_service.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _pc = PageController(initialPage: 1);
  final _mapKey = GlobalKey<MapRoomScreenState>();
  int _page = 1;

  @override
  void initState() {
    super.initState();
    // 지도 화면(초기)에서 엣지 제외 영역 등록
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExclusionRects());
  }

  @override
  void dispose() {
    GestureExclusionService.clearExclusionRects();
    _pc.dispose();
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
      if (page == 1) _mapKey.currentState?.recenterOnUser();
    });
  }

  /// 지도 화면에서는 좌/우 40dp 엣지를 시스템 백 제스처에서 제외합니다.
  /// 다른 화면에서는 제외 영역을 해제해 PopScope 가 백 제스처를 처리합니다.
  void _syncExclusionRects() {
    if (!mounted) return;
    if (_page != 1) {
      GestureExclusionService.clearExclusionRects();
      return;
    }
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const w = 40.0; // 엣지 스트립 너비(논리 픽셀)
    GestureExclusionService.setExclusionRects([
      Rect.fromLTWH(0, 0, w, size.height),
      Rect.fromLTWH(size.width - w, 0, w, size.height),
    ], dpr);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 지도 화면에서만 앱 종료 허용, 나머지는 지도로 복귀
      canPop: _page == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(1);
      },
      child: Stack(
        children: [
          PageView(
            controller: _pc,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) {
              setState(() => _page = p);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _syncExclusionRects());
            },
            children: [
              // 사용자 룸: 전체 화면 스와이프로 지도 복귀
              _SwipeWrapper(
                onSwipeLeft: () => _goTo(1),
                onSwipeRight: null,
                child: const UserRoomScreen(),
              ),
              // 지도: 포인터 콜백으로 스와이프 처리
              MapRoomScreen(
                key: _mapKey,
                onSwipeToUserRoom: () => _goTo(0),
                onSwipeToPartnerRoom: () => _goTo(2),
              ),
              // 파트너 룸: 전체 화면 스와이프로 지도 복귀
              _SwipeWrapper(
                onSwipeLeft: null,
                onSwipeRight: () => _goTo(1),
                child: const PartnerRoomScreen(),
              ),
            ],
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
    return Listener(
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
    );
  }
}
