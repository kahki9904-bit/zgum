import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 파트너 무료이용 행사 서비스.
/// - 총 90일 크레딧, 알림 ON인 시간만 소모
/// - 하루 최대 3회 등록
/// 행사 종료 시 이 파일과 promotions/ 폴더 전체를 삭제.
class FreeUseService {
  FreeUseService._();
  static final FreeUseService instance = FreeUseService._();

  static const int totalDays = 90;
  static const int dailyLimit = 3;

  static const _kStartMs = 'promo_fu_start_ms';
  static const _kPausedMs = 'promo_fu_paused_ms';
  static const _kOffSinceMs = 'promo_fu_off_since_ms';
  static const _kDailyCount = 'promo_fu_daily_count';
  static const _kDailyDate = 'promo_fu_daily_date';
  static const _kIntroShown = 'promo_fu_intro_shown';

  Future<bool> isIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIntroShown) ?? false;
  }

  // 인트로 팝업 확인만 기록 (크레딧 시작은 알림 허용 시점)
  Future<void> markIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroShown, true);
  }

  Future<void> _startCredit() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_kStartMs) != null) return;
    await prefs.setInt(_kStartMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStartMs) != null;
  }

  // 앱이 포그라운드로 돌아올 때 알림 상태 동기화
  // 인트로 확인 후 알림이 ON 된 순간 크레딧 시작
  Future<NotificationSyncResult> syncNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final introShown = prefs.getBool(_kIntroShown) ?? false;
    if (!introShown) return NotificationSyncResult.unchanged;

    final notifOn = await isNotificationEnabled();
    final started = prefs.getInt(_kStartMs) != null;
    final offSince = prefs.getInt(_kOffSinceMs);

    if (notifOn) {
      if (!started) {
        // 알림 허용 최초 감지 → 크레딧 시작
        await _startCredit();
        return NotificationSyncResult.resumed;
      } else if (offSince != null) {
        // 일시중단 후 알림 복귀 → 정지 시간 누적
        final pausedMs = prefs.getInt(_kPausedMs) ?? 0;
        final addedPause = DateTime.now().millisecondsSinceEpoch - offSince;
        await prefs.setInt(_kPausedMs, pausedMs + addedPause);
        await prefs.remove(_kOffSinceMs);
        return NotificationSyncResult.resumed;
      }
    } else if (!notifOn && offSince == null && started) {
      // 알림 OFF 전환 → 정지 시각 기록
      await prefs.setInt(_kOffSinceMs, DateTime.now().millisecondsSinceEpoch);
      return NotificationSyncResult.paused;
    }
    return NotificationSyncResult.unchanged;
  }

  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_kStartMs);
    if (startMs == null) return false;
    final notifOn = await isNotificationEnabled();
    if (!notifOn) return false;
    return _remainingDays(prefs, startMs) > 0;
  }

  Future<int> remainingDays() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_kStartMs);
    if (startMs == null) return 0;
    return _remainingDays(prefs, startMs);
  }

  int _remainingDays(SharedPreferences prefs, int startMs) {
    final pausedMs = prefs.getInt(_kPausedMs) ?? 0;
    final offSince = prefs.getInt(_kOffSinceMs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentPause = offSince != null ? (now - offSince) : 0;
    final activeMs = (now - startMs) - pausedMs - currentPause;
    final activeDays = (activeMs / (24 * 3600 * 1000)).floor();
    return (totalDays - activeDays).clamp(0, totalDays);
  }

  Future<bool> canRegisterToday() async {
    if (!await isActive()) return false;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    if (prefs.getString(_kDailyDate) != today) return true;
    return (prefs.getInt(_kDailyCount) ?? 0) < dailyLimit;
  }

  Future<void> recordRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final count = (prefs.getString(_kDailyDate) == today)
        ? (prefs.getInt(_kDailyCount) ?? 0)
        : 0;
    await prefs.setString(_kDailyDate, today);
    await prefs.setInt(_kDailyCount, count + 1);
  }

  Future<bool> isNotificationEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

enum NotificationSyncResult { resumed, paused, unchanged }
