import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/space_model.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static final _mockSpace = SpaceModel(
    id: 'mock_001',
    title: '서울시립미술관 기획전',
    lat: 37.5650,
    lng: 126.9752,
    essentialAction: '오늘 18:00 마감 · 무료 전시',
    ownerId: 'system',
    targetTime: DateTime.now().add(const Duration(hours: 2)),
    category: SpaceCategories.culture,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 앱 로고 ─────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 32, 28, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _AppLogo(),
              ),
            ),

            // ── 중앙 히어로 문구 ─────────────────────────────────────────────
            const Expanded(child: _HeroSection()),

            // ── 하단 데이터 카드 ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _SpaceCard(space: _mockSpace),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 앱 로고 ───────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Z:GUM',
      style: TextStyle(
        color: AppTheme.deepBlue,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
      ),
    );
  }
}

// ── 히어로 섹션 ───────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 카피
          const Text(
            '탐험을\n시작합니다',
            style: TextStyle(
              color: AppTheme.deepBlue,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -1.0,
            ),
          ),

          const SizedBox(height: 20),

          // 서브 카피
          Text(
            '지금 이 순간,\n당신 주변의 가치를 발견하세요.',
            style: TextStyle(
              color: AppTheme.deepBlue.withValues(alpha: 0.45),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.7,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 데이터 카드 (SpaceModel 연결 확인용) ──────────────────────────────────────

class _SpaceCard extends StatelessWidget {
  final SpaceModel space;
  const _SpaceCard({required this.space});

  @override
  Widget build(BuildContext context) {
    final mins = space.minutesLeft;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.deepBlue.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 카테고리 이모지
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(SpaceCategoryStyle.colorOf(space.category)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.title,
                  style: const TextStyle(
                    color: AppTheme.deepBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  space.essentialAction,
                  style: TextStyle(
                    color: AppTheme.deepBlue.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 남은 시간 배지
          if (space.isRealtime)
            _TimeBadge(mins: mins, isUrgent: space.isUrgent),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final int mins;
  final bool isUrgent;
  const _TimeBadge({required this.mins, required this.isUrgent});

  String get _label {
    if (mins <= 0) return '마감';
    if (mins < 60) return '$mins분';
    return '${mins ~/ 60}시간';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        isUrgent ? const Color(0xFFCC0000) : AppTheme.deepBlue.withValues(alpha: 0.65);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        Text(
          '남음',
          style: TextStyle(
              color: color.withValues(alpha: 0.6), fontSize: 10),
        ),
      ],
    );
  }
}
