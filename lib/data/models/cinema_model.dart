import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

// ── 상영 일정 ──────────────────────────────────────────────────────────────────

class ScreeningSchedule extends Equatable {
  final String movieTitle;
  final String? genre;
  final String? ageRating;     // e.g. '15세', '전체관람가'
  final int runtimeMinutes;
  final DateTime startAt;

  const ScreeningSchedule({
    required this.movieTitle,
    this.genre,
    this.ageRating,
    required this.runtimeMinutes,
    required this.startAt,
  });

  DateTime get endAt => startAt.add(Duration(minutes: runtimeMinutes));

  /// 상영 시작 여부
  bool isStarted({DateTime? now}) =>
      startAt.isBefore(now ?? DateTime.now());

  /// 상영 종료 여부 (런타임 초과)
  bool isEnded({DateTime? now}) =>
      endAt.isBefore(now ?? DateTime.now());

  /// 상영 중 여부 (시작됐지만 종료되지 않음)
  bool isNowPlaying({DateTime? now}) {
    final n = now ?? DateTime.now();
    return isStarted(now: n) && !isEnded(now: n);
  }

  /// 시작까지 남은 분. 이미 시작됐으면 음수.
  int minutesUntilStart({DateTime? now}) =>
      startAt.difference(now ?? DateTime.now()).inMinutes;

  /// 화면 표시용 시작 시각 문자열 ('HH:MM')
  String get timeLabel {
    final h = startAt.hour.toString().padLeft(2, '0');
    final m = startAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 런타임을 'X시간 Y분' 또는 'Y분' 형태로 반환
  String get runtimeLabel {
    final h = runtimeMinutes ~/ 60;
    final m = runtimeMinutes % 60;
    if (h > 0 && m > 0) return '$h시간 $m분';
    if (h > 0) return '$h시간';
    return '$m분';
  }

  @override
  List<Object?> get props => [movieTitle, startAt];
}

// ── 영화관 ────────────────────────────────────────────────────────────────────

class CinemaModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final List<ScreeningSchedule> screenings;

  const CinemaModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.screenings,
  });

  /// 현재 시각 이후 상영분 (종료 포함, 시작순 정렬).
  /// [hideEnded]: true이면 이미 끝난 상영은 제외합니다.
  List<ScreeningSchedule> upcomingScreenings({
    DateTime? now,
    bool hideEnded = true,
  }) {
    final n = now ?? DateTime.now();
    return screenings
        .where((s) => hideEnded ? !s.isEnded(now: n) : true)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// 번개 추천 후보: 아직 시작 전 & 도착 가능 & 3시간 이내
  List<ScreeningSchedule> recommendableScreenings({
    required DateTime now,
    required int walkMinutes,
  }) {
    return screenings
        .where((s) {
          if (s.isStarted(now: now)) return false;
          final minsUntil = s.minutesUntilStart(now: now);
          return minsUntil >= walkMinutes && minsUntil <= 180;
        })
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  List<Object?> get props => [id];
}
