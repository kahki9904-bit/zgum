import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventStats {
  final int visitorCount;
  final int traceCount;

  const EventStats({this.visitorCount = 0, this.traceCount = 0});

  EventStats incrementVisitor() =>
      EventStats(visitorCount: visitorCount + 1, traceCount: traceCount);

  EventStats incrementTrace() =>
      EventStats(visitorCount: visitorCount, traceCount: traceCount + 1);
}

class EventStatsNotifier extends StateNotifier<Map<String, EventStats>> {
  EventStatsNotifier() : super(const {});

  /// 지오펜스 3분 체류 달성 시 호출 — 단순 방문
  void recordVisit(String eventId) {
    final current = state[eventId] ?? const EventStats();
    state = Map.of(state)..[eventId] = current.incrementVisitor();
  }

  /// 체크인 완료 시 호출 — 흔적 기록
  void recordTrace(String eventId) {
    final current = state[eventId] ?? const EventStats();
    state = Map.of(state)..[eventId] = current.incrementTrace();
  }

  EventStats statsFor(String eventId) =>
      state[eventId] ?? const EventStats();
}

final eventStatsProvider =
    StateNotifierProvider<EventStatsNotifier, Map<String, EventStats>>(
  (_) => EventStatsNotifier(),
);
