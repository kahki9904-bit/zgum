class EventFade {
  EventFade._();

  /// 종료 후 1시간에 걸쳐 opacity 1.0 → 0.0
  static double opacity(DateTime endDateTime, DateTime now) {
    final elapsed = now.difference(endDateTime);
    if (elapsed.isNegative) return 1.0;
    final secs = elapsed.inSeconds;
    if (secs >= 3600) return 0.0;
    return 1.0 - secs / 3600.0;
  }

  /// 종료 후 30분부터 그레이톤
  static bool isGrayed(DateTime endDateTime, DateTime now) {
    final elapsed = now.difference(endDateTime);
    return !elapsed.isNegative && elapsed.inMinutes >= 30;
  }

  /// 종료 후 1시간 — 완전 소멸
  static bool isFullyExpired(DateTime endDateTime, DateTime now) {
    return now.difference(endDateTime).inSeconds >= 3600;
  }

  /// "-05m" 형식. 활성 상태이거나 완전 소멸이면 null
  static String? negativeLabel(DateTime endDateTime, DateTime now) {
    final elapsed = now.difference(endDateTime);
    if (elapsed.isNegative || elapsed.inSeconds >= 3600) return null;
    return '-${elapsed.inMinutes.toString().padLeft(2, '0')}m';
  }
}
