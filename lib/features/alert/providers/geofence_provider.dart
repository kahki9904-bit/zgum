import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/geo_utils.dart';
import '../../../core/providers/user_location_provider.dart';
import '../models/partner_event.dart';
import 'alert_provider.dart';
import 'event_stats_provider.dart';

const _kRadiusKm = 0.2;       // 200m 반경
const _kDwellMinutes = 3;     // 3분 체류
const _kCheckSec = 30;        // 30초 간격 체크
const _kPrefPrefix = 'geo_alerted_';

class GeofenceNotifier extends StateNotifier<PartnerEvent?> {
  final Ref _ref;
  Timer? _timer;

  // eventId → 반경 진입 시각
  final Map<String, DateTime> _entryTimes = {};

  GeofenceNotifier(this._ref) : super(null) {
    _timer = Timer.periodic(
      const Duration(seconds: _kCheckSec),
      (_) => _check(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 흔적 팝업 닫기 (나중에 탭 or 체크인 완료 후)
  void dismiss() {
    if (mounted) state = null;
  }

  Future<void> _check() async {
    if (!mounted) return;
    final userLoc = _ref.read(userLocationProvider);
    final events = _ref.read(partnerAlertProvider);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    // 만료된 이벤트의 진입 기록 정리
    _entryTimes.removeWhere(
      (id, _) => !events.any((e) => e.id == id && !e.isExpired),
    );

    for (final event in events) {
      if (event.isExpired) continue;

      // 이벤트 종료까지 3분 미만이면 의미 없는 알림이므로 건너뜀
      if (event.expiresAt.difference(now).inMinutes < _kDwellMinutes) continue;

      // 오늘 이미 알림 발송한 이벤트는 하루 1회 제한
      final key = '$_kPrefPrefix${event.id}';
      if (prefs.getString(key) == today) continue;

      final distKm = haversineKm(userLoc, event.location);

      if (distKm <= _kRadiusKm) {
        // 반경 안 — 진입 시각 기록 또는 체류 시간 확인
        final entry = _entryTimes[event.id];
        if (entry == null) {
          _entryTimes[event.id] = now;
        } else if (now.difference(entry).inMinutes >= _kDwellMinutes) {
          // 3분 체류 달성
          await prefs.setString(key, today);
          _entryTimes.remove(event.id);
          _ref.read(eventStatsProvider.notifier).recordVisit(event.id);
          if (mounted) state = event;
          return; // 한 번에 하나의 이벤트만 처리
        }
      } else {
        // 반경 이탈 → 타이머 초기화 (다시 들어오면 재시작)
        _entryTimes.remove(event.id);
      }
    }
  }
}

final geofenceProvider =
    StateNotifierProvider<GeofenceNotifier, PartnerEvent?>(
  (ref) => GeofenceNotifier(ref),
);
