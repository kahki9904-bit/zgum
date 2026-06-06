import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/geo_utils.dart';
import '../../../data/models/cinema_model.dart';

/// 영화관 상세 바텀 시트 — 현재 시각 이후 상영 시간표를 보여줍니다.
///
/// ## 상영 상태별 UI
/// - 종료된 상영: 리스트에서 완전히 제거 (hideEnded = true)
/// - 상영 중: 회색 텍스트 + '상영중' 배지
/// - 30분 이내 시작: 강조 색상 + 'N분 후' 배지
/// - 일반 예정: 기본 스타일
class CinemaDetailSheet {
  CinemaDetailSheet._();

  static Future<void> show(
    BuildContext context, {
    required CinemaModel cinema,
    required LatLng userLocation,
    required VoidCallback onGoToCinema,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CinemaSheet(
        cinema: cinema,
        userLocation: userLocation,
        onGoToCinema: onGoToCinema,
      ),
    );
  }
}

// ── 시트 본문 ──────────────────────────────────────────────────────────────────

class _CinemaSheet extends StatelessWidget {
  final CinemaModel cinema;
  final LatLng userLocation;
  final VoidCallback onGoToCinema;

  const _CinemaSheet({
    required this.cinema,
    required this.userLocation,
    required this.onGoToCinema,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final walkMins = walkingMinutes(userLocation, cinema.location);
    final schedule = cinema.upcomingScreenings(now: now, hideEnded: true);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.30,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.bottomSheetTheme.backgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── 드래그 핸들 ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // ── 극장 헤더 ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🎬',
                            style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cinema.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.4)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    cinema.address,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.directions_walk_outlined,
                                    size: 12,
                                    color: Color(0xFF4ECDC4)),
                                const SizedBox(width: 2),
                                Text(
                                  '도보 $walkMins분',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4ECDC4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 📍 극장으로 가기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onGoToCinema();
                      },
                      icon: const Text('📍',
                          style: TextStyle(fontSize: 16)),
                      label: const Text('극장으로 가기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── 상영 시간표 ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  Text(
                    '오늘 상영 시간표',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${schedule.length}편',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: schedule.isEmpty
                  ? _NoScheduleView(controller: controller)
                  : ListView.separated(
                      controller: controller,
                      padding: EdgeInsets.fromLTRB(
                          16, 4, 16,
                          MediaQuery.of(context).padding.bottom + 20),
                      itemCount: schedule.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) => _ScreeningRow(
                        screening: schedule[i],
                        now: now,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 상영 행 ───────────────────────────────────────────────────────────────────

class _ScreeningRow extends StatelessWidget {
  final ScreeningSchedule screening;
  final DateTime now;

  const _ScreeningRow({required this.screening, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final nowPlaying = screening.isNowPlaying(now: now);
    final minsUntil = screening.minutesUntilStart(now: now);
    final isSoon = !nowPlaying && minsUntil <= 30; // 30분 이내 시작
    final isUrgent = !nowPlaying && minsUntil <= 60;

    // 색상 결정
    final Color timeColor;
    final Color titleColor;
    if (nowPlaying) {
      timeColor = cs.onSurface.withValues(alpha: 0.35);
      titleColor = cs.onSurface.withValues(alpha: 0.40);
    } else if (isSoon) {
      timeColor = const Color(0xFFE74C3C);
      titleColor = cs.onSurface;
    } else if (isUrgent) {
      timeColor = const Color(0xFFD4AF37);
      titleColor = cs.onSurface;
    } else {
      timeColor = cs.onSurface.withValues(alpha: 0.70);
      titleColor = cs.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 시작 시각
          SizedBox(
            width: 46,
            child: Text(
              screening.timeLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: timeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 영화 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screening.movieTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (screening.genre != null) ...[
                      _SmallTag(screening.genre!, faded: nowPlaying),
                      const SizedBox(width: 5),
                    ],
                    if (screening.ageRating != null)
                      _SmallTag(screening.ageRating!, faded: nowPlaying),
                    const SizedBox(width: 5),
                    Text(
                      screening.runtimeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 상태 배지
          _StatusBadge(
            nowPlaying: nowPlaying,
            minsUntil: minsUntil,
            isSoon: isSoon,
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  final bool faded;
  const _SmallTag(this.text, {this.faded = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: faded ? 0.04 : 0.07),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: cs.onSurface.withValues(alpha: faded ? 0.3 : 0.55),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool nowPlaying;
  final int minsUntil;
  final bool isSoon;

  const _StatusBadge({
    required this.nowPlaying,
    required this.minsUntil,
    required this.isSoon,
  });

  @override
  Widget build(BuildContext context) {
    if (nowPlaying) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('상영중',
            style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600)),
      );
    }

    if (isSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$minsUntil분 후',
          style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700),
        ),
      );
    }

    if (minsUntil <= 60) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
        ),
        child: Text(
          '$minsUntil분 후',
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w600),
        ),
      );
    }

    // 일반 예정
    return Text(
      '예정',
      style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
    );
  }
}

// ── 빈 시간표 ─────────────────────────────────────────────────────────────────

class _NoScheduleView extends StatelessWidget {
  final ScrollController controller;
  const _NoScheduleView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(32),
      children: [
        const Center(child: Text('🎬', style: TextStyle(fontSize: 40))),
        const SizedBox(height: 12),
        Text(
          '오늘 남은 상영이 없습니다',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
