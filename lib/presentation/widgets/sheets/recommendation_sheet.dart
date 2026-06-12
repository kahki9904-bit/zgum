import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/geo_utils.dart';
import '../../../core/time_utils.dart' as tu;
import '../../../data/models/cinema_model.dart';
import '../../../data/models/cultural_event.dart';
import '../../../services/time_service.dart';
import 'cinema_detail_sheet.dart';
import 'event_detail_sheet.dart';

/// ⚡ 즉흥 코스 추천 바텀 시트.
///
/// ## 매칭 알고리즘
/// 1. 전체 이벤트에서 [isRecommendable] 필터 적용 (30분 이상 && 3시간 이내 종료)
/// 2. 각 이벤트의 **달성 가능성 점수** 계산:
///    score = remainingMinutes − walkMinutes × 2
/// 3. 문화·공연(public) / 파트너 혜택(partner) / 영화관 각각 최고 점수 선택
/// 4. 3-섹션 코스: 🎬 영화 → 이어서 → 🎭 문화공연 → 이어서 → 🔥 파트너
class RecommendationSheet {
  RecommendationSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<CulturalEvent> events,
    required LatLng userLocation,
    required TimeService timeService,
    List<CinemaModel> cinemas = const [],
  }) async {
    final now = timeService.now();
    final candidates = events
        .where((e) => tu.isRecommendable(e.endDateTime, now: now))
        .toList();

    // 달성 가능성 점수 기준 내림차순
    candidates.sort((a, b) => _eventScore(b, userLocation, now: now)
        .compareTo(_eventScore(a, userLocation, now: now)));

    final cultural =
        candidates.firstWhereOrNull((e) => e.source == EventSource.public);
    final partner =
        candidates.firstWhereOrNull((e) => e.source == EventSource.partner);
    final cinemaMatch = _bestCinemaMatch(cinemas, userLocation, now);

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecommendationSheet(
        cultural: cultural,
        partner: partner,
        cinemaMatch: cinemaMatch,
        userLocation: userLocation,
        timeService: timeService,
      ),
    );
  }

  // ── 점수 계산 ────────────────────────────────────────────────────────────────

  static int _eventScore(CulturalEvent e, LatLng from,
      {required DateTime now}) {
    final walk = walkingMinutes(from, e.location);
    final remaining = tu.minutesLeft(e.endDateTime, now: now);
    return remaining - walk * 2;
  }

  /// 영화관 최적 매칭: 도착 가능 && 3시간 이내 시작 상영 중 점수 최고
  static _CinemaMatch? _bestCinemaMatch(
      List<CinemaModel> cinemas, LatLng from, DateTime now) {
    _CinemaMatch? best;
    int bestScore = -9999;

    for (final cinema in cinemas) {
      final walkMins = walkingMinutes(from, cinema.location);
      final recs = cinema.recommendableScreenings(
          now: now, walkMinutes: walkMins);
      for (final s in recs) {
        final minsUntil = s.minutesUntilStart(now: now);
        final score = minsUntil - walkMins * 2;
        if (score > bestScore) {
          bestScore = score;
          best = _CinemaMatch(cinema: cinema, screening: s);
        }
      }
    }
    return best;
  }
}

// ── 내부 데이터 클래스 ────────────────────────────────────────────────────────

class _CinemaMatch {
  final CinemaModel cinema;
  final ScreeningSchedule screening;
  const _CinemaMatch({required this.cinema, required this.screening});
}

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// ── 시트 본문 ──────────────────────────────────────────────────────────────────

class _RecommendationSheet extends StatelessWidget {
  final CulturalEvent? cultural;
  final CulturalEvent? partner;
  final _CinemaMatch? cinemaMatch;
  final LatLng userLocation;
  final TimeService timeService;

  const _RecommendationSheet({
    required this.cultural,
    required this.partner,
    required this.cinemaMatch,
    required this.userLocation,
    required this.timeService,
  });

  bool get _hasAnything =>
      cultural != null || partner != null || cinemaMatch != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: _hasAnything ? 0.60 : 0.38,
      minChildSize: 0.30,
      maxChildSize: 0.88,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.bottomSheetTheme.backgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
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

            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('⚡',
                        style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '지금 바로 즉흥 코스!',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '30분~3시간 이내 마감되는 주변 혜택',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 본문
            Expanded(
              child: _hasAnything
                  ? _CourseList(
                      controller: controller,
                      cinemaMatch: cinemaMatch,
                      cultural: cultural,
                      partner: partner,
                      userLocation: userLocation,
                      timeService: timeService,
                    )
                  : _EmptyState(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 코스 목록 ─────────────────────────────────────────────────────────────────

class _CourseList extends StatelessWidget {
  final ScrollController controller;
  final _CinemaMatch? cinemaMatch;
  final CulturalEvent? cultural;
  final CulturalEvent? partner;
  final LatLng userLocation;
  final TimeService timeService;

  const _CourseList({
    required this.controller,
    required this.cinemaMatch,
    required this.cultural,
    required this.partner,
    required this.userLocation,
    required this.timeService,
  });

  @override
  Widget build(BuildContext context) {
    // 표시할 섹션 목록 (순서: 영화 → 문화공연 → 파트너)
    final sections = <Widget>[];

    if (cinemaMatch != null) {
      sections.add(const _SectionLabel(icon: '🎬', text: '영화'));
      sections.add(const SizedBox(height: 8));
      sections.add(_CinemaCard(match: cinemaMatch!, userLocation: userLocation));
    }

    if (cultural != null) {
      if (sections.isNotEmpty) sections.add(const _CourseDivider());
      sections.add(const _SectionLabel(icon: '🎭', text: '문화·공연'));
      sections.add(const SizedBox(height: 8));
      sections.add(_EventCard(
        event: cultural!,
        userLocation: userLocation,
        timeService: timeService,
        onTap: () {
          Navigator.pop(context);
          EventDetailSheet.show(
            context,
            cultural!,
            timeService: timeService,
            userLocation: userLocation,
          );
        },
      ));
    }

    if (partner != null) {
      if (sections.isNotEmpty) sections.add(const _CourseDivider());
      sections.add(const _SectionLabel(icon: '🔥', text: '파트너 혜택'));
      sections.add(const SizedBox(height: 8));
      sections.add(_EventCard(
        event: partner!,
        userLocation: userLocation,
        timeService: timeService,
        onTap: () {
          Navigator.pop(context);
          EventDetailSheet.show(
            context,
            partner!,
            timeService: timeService,
            userLocation: userLocation,
          );
        },
      ));
    }

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 20),
      children: sections,
    );
  }
}

// ── 영화관 카드 ───────────────────────────────────────────────────────────────

class _CinemaCard extends StatelessWidget {
  final _CinemaMatch match;
  final LatLng userLocation;

  const _CinemaCard({required this.match, required this.userLocation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final minsUntil = match.screening.minutesUntilStart(now: now);
    final isUrgent = minsUntil <= 60;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUrgent
              ? const Color(0xFF1565C0).withValues(alpha: 0.5)
              : cs.onSurface.withValues(alpha: 0.1),
          width: isUrgent ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          CinemaDetailSheet.show(
            context,
            cinema: match.cinema,
            userLocation: userLocation,
            onGoToCinema: () {},
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 영화 제목 + 시작 임박 배지
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      match.screening.movieTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$minsUntil분 후',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // 극장명
              Row(
                children: [
                  Icon(Icons.theater_comedy_outlined,
                      size: 13,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    match.cinema.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  if (match.screening.genre != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      match.screening.genre!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _PillTag(
                    icon: Icons.movie_outlined,
                    label: '$minsUntil분 후 시작',
                    color: isUrgent
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.screening.runtimeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    CinemaDetailSheet.show(
                      context,
                      cinema: match.cinema,
                      userLocation: userLocation,
                      onGoToCinema: () {},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38), padding: EdgeInsets.zero),
                  child: const Text('상영 시간표 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 섹션 레이블 ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}

// ── 코스 구분선 ───────────────────────────────────────────────────────────────

class _CourseDivider extends StatelessWidget {
  const _CourseDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.arrow_downward,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  '이어서',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── 이벤트 카드 ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CulturalEvent event;
  final LatLng userLocation;
  final TimeService timeService;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.userLocation,
    required this.timeService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remaining = timeService.remainingLabel(event.endDateTime);
    final isUrgent = timeService.isUrgentPulse(event.endDateTime);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUrgent
              ? const Color(0xFFE74C3C).withValues(alpha: 0.4)
              : cs.onSurface.withValues(alpha: 0.1),
          width: isUrgent ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '마감 임박',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.venue,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  _PillTag(
                    icon: Icons.timer_outlined,
                    label: remaining,
                    color: isUrgent
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFFD4AF37),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: EdgeInsets.zero),
                  child: const Text('상세 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PillTag(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ScrollController controller;
  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(32),
      children: [
        const Center(
          child: Text('🔍', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 16),
        Text(
          '지금 주변에 맞는 이벤트가 없어요',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '30분~3시간 내에 종료되는\n이벤트가 있을 때 다시 눌러보세요!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}
