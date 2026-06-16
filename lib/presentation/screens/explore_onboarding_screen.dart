import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';
import '../../core/interfaces/map_engine.dart';
import '../../core/models/map_marker_model.dart';
import '../../core/theme.dart';
import '../../features/map_room/engines/flutter_map_engine.dart';
import '../shell/shell_screen.dart';

// ── 화면 상태 머신 ─────────────────────────────────────────────────────────────

enum _Phase { locating, cursor, permCard, filterCard }

// ── 카테고리 정의 ──────────────────────────────────────────────────────────────

class _Cat {
  final String key;
  final String label;
  final String? emoji;
  const _Cat(this.key, this.label, this.emoji);
}

const _categories = <_Cat>[
  _Cat('movie',    '영화',   null),
  _Cat('theater',  '연극',   null),
  _Cat('exhibit',  '전시',   null),
  _Cat('zoo',      '동물원',  null),
  _Cat('park',     '유원지',  null),
  _Cat('shopping', '상권',   null),
];

typedef _Radius = ({String label, double km});
const List<_Radius> _radii = [
  (label: '500m', km: 0.5),
  (label: '1km',  km: 1.0),
  (label: '3km',  km: 3.0),
  (label: '전체',  km: 10.0),
];

// ── 메인 화면 ──────────────────────────────────────────────────────────────────

class ExploreOnboardingScreen extends StatefulWidget {
  const ExploreOnboardingScreen({super.key});

  @override
  State<ExploreOnboardingScreen> createState() =>
      _ExploreOnboardingScreenState();
}

class _ExploreOnboardingScreenState extends State<ExploreOnboardingScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.locating;
  LatLng _center = AppConstants.defaultLocation;
  final MapEngine _engine = FlutterMapEngine();
  late final MapEngineController _mapCtrl;

  final Set<String> _selectedKeys = {};
  double _radiusKm = 1.0;

  late final AnimationController _cardAnim;

  MapCoordinate get _centerCoord =>
      MapCoordinate(_center.latitude, _center.longitude);

  @override
  void initState() {
    super.initState();
    _mapCtrl = _engine.createController();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _runFlow();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _runFlow() async {
    // 시스템 다이얼로그 없이 기존 권한 상태만 조회
    final perm = await Geolocator.checkPermission();
    final granted = perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;

    if (granted) {
      _center = await _fetchPosition();
    }

    if (!mounted) return;

    // 커서 페이드인
    setState(() => _phase = _Phase.cursor);

    // 지도를 사용자 위치로 이동
    await Future.delayed(const Duration(milliseconds: 300));
    _mapCtrl.move(_centerCoord, AppConstants.defaultZoom);

    // 커서 안착 감상 후 카드 등장
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() => _phase = granted ? _Phase.filterCard : _Phase.permCard);
    _cardAnim.forward();
  }

  Future<LatLng> _fetchPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return AppConstants.defaultLocation;
    }
  }

  // 사용자가 "탐험 시작하기" 버튼 → 시스템 권한 다이얼로그
  Future<void> _onPermit() async {
    final perm = await Geolocator.requestPermission();
    if (!mounted) return;

    if (perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always) {
      final loc = await _fetchPosition();
      if (!mounted) return;
      setState(() => _center = loc);
      _mapCtrl.move(MapCoordinate(loc.latitude, loc.longitude), AppConstants.defaultZoom);
    }

    setState(() => _phase = _Phase.filterCard);
  }

  void _proceed() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 지도: 마커 없음, UI 요소 최소화 ──────────────────────────────────
          _engine.buildWidget(
            initialCenter: _centerCoord,
            initialZoom: AppConstants.defaultZoom,
            markers: const [],
            onMarkerTap: (_) {},
            controller: _mapCtrl,
          ),

          // ── 커서: 지도 정중앙 = 카메라 타겟 = 사용자 위치 ─────────────────────
          AnimatedOpacity(
            opacity: _phase == _Phase.locating ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
            child: const Center(child: _UserCursor()),
          ),

          // ── 온보딩 카드 (하단 슬라이드업) ────────────────────────────────────
          if (_phase == _Phase.permCard || _phase == _Phase.filterCard)
            _OnboardingCard(
              phase: _phase,
              anim: _cardAnim,
              selectedKeys: _selectedKeys,
              radiusKm: _radiusKm,
              onPermit: _onPermit,
              onSkip: _proceed,
              onStart: _proceed,
              onToggle: (k) => setState(() => _selectedKeys.contains(k)
                  ? _selectedKeys.remove(k)
                  : _selectedKeys.add(k)),
              onRadius: (r) => setState(() => _radiusKm = r),
            ),
        ],
      ),
    );
  }
}

// ── 사용자 위치 커서 ────────────────────────────────────────────────────────────

class _UserCursor extends StatefulWidget {
  const _UserCursor();

  @override
  State<_UserCursor> createState() => _UserCursorState();
}

class _UserCursorState extends State<_UserCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 3.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 0.40, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 퍼져나가는 펄스 링
            Opacity(
              opacity: _fade.value,
              child: Container(
                width: 14 * _scale.value,
                height: 14 * _scale.value,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.deepBlue,
                ),
              ),
            ),
            // 고정 내부 점 (흰 테두리 + 그림자)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.deepBlue,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepBlue.withValues(alpha: 0.30),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 온보딩 카드 (슬라이드업 컨테이너) ─────────────────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final _Phase phase;
  final AnimationController anim;
  final Set<String> selectedKeys;
  final double radiusKm;
  final VoidCallback onPermit;
  final VoidCallback onSkip;
  final VoidCallback onStart;
  final ValueChanged<String> onToggle;
  final ValueChanged<double> onRadius;

  const _OnboardingCard({
    required this.phase,
    required this.anim,
    required this.selectedKeys,
    required this.radiusKm,
    required this.onPermit,
    required this.onSkip,
    required this.onStart,
    required this.onToggle,
    required this.onRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: anim,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + bottomPad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepBlue.withValues(alpha: 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // AnimatedSwitcher: permCard ↔ filterCard 콘텐츠 교체 시 크로스페이드
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: phase == _Phase.permCard
                  ? _PermContent(
                      key: const ValueKey('perm'),
                      onPermit: onPermit,
                      onSkip: onSkip,
                    )
                  : _FilterContent(
                      key: const ValueKey('filter'),
                      selectedKeys: selectedKeys,
                      radiusKm: radiusKm,
                      onToggle: onToggle,
                      onRadius: onRadius,
                      onStart: onStart,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 권한 요청 콘텐츠 ────────────────────────────────────────────────────────────

class _PermContent extends StatelessWidget {
  final VoidCallback onPermit;
  final VoidCallback onSkip;

  const _PermContent({
    super.key,
    required this.onPermit,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 주변 탐험을\n시작할까요?',
          style: TextStyle(
            color: AppTheme.deepBlue,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '위치 정보로 지금 이 순간,\n가장 가까운 문화를 발견합니다.',
          style: TextStyle(
            color: AppTheme.deepBlue.withValues(alpha: 0.50),
            fontSize: 14,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryBtn(label: '탐험 시작하기', onTap: onPermit),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: onSkip,
            child: Text(
              '나중에',
              style: TextStyle(
                color: AppTheme.deepBlue.withValues(alpha: 0.30),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 필터 선택 콘텐츠 ────────────────────────────────────────────────────────────

class _FilterContent extends StatelessWidget {
  final Set<String> selectedKeys;
  final double radiusKm;
  final ValueChanged<String> onToggle;
  final ValueChanged<double> onRadius;
  final VoidCallback onStart;

  const _FilterContent({
    super.key,
    required this.selectedKeys,
    required this.radiusKm,
    required this.onToggle,
    required this.onRadius,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 거리 필터
        const _SectionLabel('거리'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < _radii.length; i++) ...[
              Expanded(
                child: _Chip(
                  label: _radii[i].label,
                  selected: radiusKm == _radii[i].km,
                  onTap: () => onRadius(_radii[i].km),
                  squared: true,
                ),
              ),
              if (i < _radii.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // 카테고리 필터
        const _SectionLabel('카테고리'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories
              .map((c) => _Chip(
                    label: c.label,
                    emoji: c.emoji,
                    selected: selectedKeys.contains(c.key),
                    onTap: () => onToggle(c.key),
                  ))
              .toList(),
        ),

        const SizedBox(height: 26),
        _PrimaryBtn(label: '탐험 시작', onTap: onStart),
      ],
    );
  }
}

// ── 공용 소형 위젯 ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.deepBlue.withValues(alpha: 0.40),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;
  final bool squared;

  const _Chip({
    required this.label,
    this.emoji,
    required this.selected,
    required this.onTap,
    this.squared = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppTheme.deepBlue
        : AppTheme.deepBlue.withValues(alpha: 0.06);
    final fg = selected ? Colors.white : AppTheme.deepBlue.withValues(alpha: 0.65);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: squared ? 38 : null,
        padding: squared
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(squared ? 10 : 20),
        ),
        child: squared
            ? Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deepBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
