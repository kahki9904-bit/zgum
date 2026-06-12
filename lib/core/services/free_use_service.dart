import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/free_use_status.dart';

class FreeUseService {
  FreeUseService._();
  static final instance = FreeUseService._();

  static const _keyDeviceId       = 'zgum_device_id';
  static const _keyStartDate      = 'zgum_free_start';
  static const _keyStatus         = 'zgum_free_status';
  static const _keyEndedReason    = 'zgum_free_ended_reason';
  static const _keyDailyCount     = 'zgum_free_daily_count';
  static const _keyDailyDate      = 'zgum_free_daily_date';
  static const _keyExpiryPopup    = 'zgum_free_expiry_popup';
  static const _keyIntroShown     = 'zgum_free_intro_shown';
  static const _freePeriodDays    = 180;

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
    if (_prefs.getString(_keyDeviceId) == null) {
      final rng = Random();
      final id = '${DateTime.now().millisecondsSinceEpoch}_${rng.nextInt(999999)}';
      await _prefs.setString(_keyDeviceId, id);
      // 알림 허용 시에만 active로 전환 — 여기서는 상태를 설정하지 않음
    }
    await _checkExpiry();
  }

  Future<void> _checkExpiry() async {
    if (_prefs.getString(_keyStatus) != FreeUseStatus.active.name) return;
    final startStr = _prefs.getString(_keyStartDate);
    if (startStr == null) return;
    final expiry = DateTime.parse(startStr)
        .add(const Duration(days: _freePeriodDays));
    if (DateTime.now().isAfter(expiry)) {
      await _prefs.setString(_keyStatus, FreeUseStatus.ended.name);
      await _prefs.setString(_keyEndedReason, EndedReason.expired.name);
    }
  }

  FreeUseStatus get status {
    if (!_ready) return FreeUseStatus.ended;
    return _prefs.getString(_keyStatus) == FreeUseStatus.active.name
        ? FreeUseStatus.active
        : FreeUseStatus.ended;
  }

  Future<void> activateFreeUse() async {
    await _prefs.setString(_keyStartDate, DateTime.now().toIso8601String());
    await _prefs.setString(_keyStatus, FreeUseStatus.active.name);
  }

  Future<void> endByNotificationOff() async {
    await _prefs.setString(_keyStatus, FreeUseStatus.ended.name);
    await _prefs.setString(_keyEndedReason, EndedReason.notificationOff.name);
  }

  // 1일 3회 제한
  Future<bool> canRegisterToday() async {
    if (!_ready) return true;
    final today = _todayKey();
    if (_prefs.getString(_keyDailyDate) != today) return true;
    return (_prefs.getInt(_keyDailyCount) ?? 0) < 3;
  }

  Future<void> recordRegistration() async {
    if (!_ready) return;
    final today = _todayKey();
    if (_prefs.getString(_keyDailyDate) != today) {
      await _prefs.setString(_keyDailyDate, today);
      await _prefs.setInt(_keyDailyCount, 1);
    } else {
      final count = _prefs.getInt(_keyDailyCount) ?? 0;
      await _prefs.setInt(_keyDailyCount, count + 1);
    }
  }

  int get todayRemainingCount {
    if (!_ready) return 0;
    final today = _todayKey();
    if (_prefs.getString(_keyDailyDate) != today) return 3;
    return (3 - (_prefs.getInt(_keyDailyCount) ?? 0)).clamp(0, 3);
  }

  // 최초 안내 팝업
  bool get shouldShowIntroPopup =>
      _ready && !(_prefs.getBool(_keyIntroShown) ?? false);

  Future<void> markIntroShown() async =>
      _prefs.setBool(_keyIntroShown, true);

  // 만료 3일 전 팝업 (1일 1회)
  bool get shouldShowExpiryWarning {
    if (!_ready || status != FreeUseStatus.active) return false;
    final startStr = _prefs.getString(_keyStartDate);
    if (startStr == null) return false;
    final expiry = DateTime.parse(startStr)
        .add(const Duration(days: _freePeriodDays));
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    if (daysLeft > 3) return false;
    if (_prefs.getString(_keyExpiryPopup) == _todayKey()) return false;
    return true;
  }

  Future<void> markExpiryWarningShown() async =>
      _prefs.setString(_keyExpiryPopup, _todayKey());

  DateTime? get expiryDate {
    if (!_ready) return null;
    final startStr = _prefs.getString(_keyStartDate);
    if (startStr == null) return null;
    return DateTime.parse(startStr)
        .add(const Duration(days: _freePeriodDays));
  }

  int get daysUntilExpiry {
    final expiry = expiryDate;
    if (expiry == null) return 0;
    return expiry.difference(DateTime.now()).inDays.clamp(0, _freePeriodDays);
  }

  Future<void> resetForTesting() async {
    await _prefs.remove(_keyDeviceId);
    await _prefs.remove(_keyStartDate);
    await _prefs.remove(_keyStatus);
    await _prefs.remove(_keyEndedReason);
    await _prefs.remove(_keyDailyCount);
    await _prefs.remove(_keyDailyDate);
    await _prefs.remove(_keyExpiryPopup);
    await _prefs.remove(_keyIntroShown);
    await initialize();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
