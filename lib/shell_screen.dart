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
    // 페이지 전환 후 제외 영역 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExclusionRects());
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

class _SwipeWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _SwipeWrapper({
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final dx = d.velocity.pixelsPerSecond.dx;
        if (dx < -300) onSwipeLeft?.call();
        if (dx > 300) onSwipeRight?.call();
      },
      child: child,
    );
  }
}
