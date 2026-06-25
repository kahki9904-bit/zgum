import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 앱 로고 ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(28, 32, 28, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _AppLogo(),
              ),
            ),

            // ── 중앙 히어로 문구 ─────────────────────────────────────────────
            Expanded(child: _HeroSection()),

            // ── 하단 데이터 카드 ─────────────────────────────────────────────
            SizedBox(height: 32),
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
