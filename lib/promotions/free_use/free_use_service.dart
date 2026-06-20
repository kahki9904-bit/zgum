import 'package:shared_preferences/shared_preferences.dart';

/// 파트너 무료이용 행사 서비스.
/// - 앱 설치일 기준 180일 크레딧
/// - 하루 최대 3회 등록
/// 행사 종료 시 이 파일과 promotions/ 폴더 전체를 삭제.
class FreeUseService {
  FreeUseService._();
  static final FreeUseService instance = FreeUseService._();

  static const int totalDays = 180;
  static const int dailyLimit = 3;

  static const _kStartMs = 'promo_fu_start_ms';
  static const _kDailyCount = 'promo_fu_daily_count';
  static const _kDailyDate = 'promo_fu_daily_date';
  static const _kIntroShown = 'promo_fu_intro_shown';

  Future<bool> isIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIntroShown) ?? false;
  }

  Future<void> markIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroShown, true);
  }

  /// 앱 최초 실행 시 크레딧 시작. 이미 시작된 경우 무시.
  Future<void> startOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_kStartMs) != null) return;
    await prefs.setInt(_kStartMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStartMs) != null;
  }

  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_kStartMs);
    if (startMs == null) return false;
    return _remainingDays(startMs) > 0;
  }

  Future<int> remainingDays() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_kStartMs);
    if (startMs == null) return 0;
    return _remainingDays(startMs);
  }

  int _remainingDays(int startMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeDays = ((now - startMs) / (24 * 3600 * 1000)).floor();
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

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
