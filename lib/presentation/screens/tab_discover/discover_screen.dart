import 'package:flutter/material.dart';

/// 탭 2 — 발견 (목적형 카테고리 탐색)
///
/// hasTimeInfo = false 인 SpaceModel을 카테고리별로 표시합니다.
/// 다음 단계에서 SpaceModel 카테고리 그리드를 통합합니다.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                '발견',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '카테고리 탐색',
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
