import 'package:flutter/material.dart';

/// 탭 3 — 나 (프로필 및 설정)
///
/// 사용자 프로필, 즐겨찾기, 앱 설정을 표시합니다.
/// 다음 단계에서 인증/설정 기능을 통합합니다.
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                '나',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '프로필 및 설정',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
