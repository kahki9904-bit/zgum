import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

enum LocationStatus { granted, denied, deniedForever, serviceDisabled }

enum LocationStep {
  gps,       // 정확한 GPS
  lastKnown, // 이전 세션 저장 위치
  network,   // Wi-Fi·기지국 유추
  manual,    // 사용자 직접 이동
}

class LocationResult {
  final LatLng position;
  final LocationStatus status;
  final LocationStep step;
  final double? accuracy;

  const LocationResult({
    required this.position,
    required this.status,
    required this.step,
    this.accuracy,
  });

  bool get isActualLocation => status == LocationStatus.granted;
  bool get needsManual => step == LocationStep.manual;
  bool get isEstimated =>
      step == LocationStep.lastKnown || step == LocationStep.network;
}

class LocationService {
  static const _kLastLatKey = 'zgum_last_lat';
  static const _kLastLngKey = 'zgum_last_lng';
  static const _accuracyThreshold = 50.0; // 미터


  // ── 위치 권한 확인 ─────────────────────────────────────────────────────────

  Future<LocationStatus> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    return LocationStatus.granted;
  }

  // ── 마지막 위치 저장·불러오기 ────────────────────────────────────────────────

  Future<void> saveLastKnown(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastLatKey, pos.latitude);
    await prefs.setDouble(_kLastLngKey, pos.longitude);
  }

  Future<LatLng?> loadLastKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLastLatKey);
    final lng = prefs.getDouble(_kLastLngKey);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  // ── 메인 위치 획득 (4단계 폴백) ────────────────────────────────────────────

  Future<LocationResult> acquireLocation() async {
    final status = await _checkPermission();

    if (status != LocationStatus.granted) {
      final last = await loadLastKnown();
      if (last != null) {
        return LocationResult(
            position: last, status: status, step: LocationStep.lastKnown);
      }
      return LocationResult(
          position: AppConstants.defaultLocation,
          status: status,
          step: LocationStep.manual);
    }

    // 1단계: 정확한 GPS. 앱 진입 지연을 줄이기 위해 오래 붙잡지 않는다.
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      final result = LatLng(pos.latitude, pos.longitude);
      if (pos.accuracy <= _accuracyThreshold) {
        await saveLastKnown(result);
        return LocationResult(
            position: result,
            status: LocationStatus.granted,
            step: LocationStep.gps,
            accuracy: pos.accuracy);
      }
      // GPS는 잡혔지만 정확도 미달 → 네트워크 먼저 시도 후 비교
      final gpsCandidate = (position: result, accuracy: pos.accuracy);

      // 3단계: 네트워크 위치 (Wi-Fi·기지국)
      try {
        final netPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        );
        final netResult = LatLng(netPos.latitude, netPos.longitude);
        if (netPos.accuracy <= gpsCandidate.accuracy) {
          await saveLastKnown(netResult);
          return LocationResult(
              position: netResult,
              status: LocationStatus.granted,
              step: LocationStep.network,
              accuracy: netPos.accuracy);
        }
      } catch (_) {}

      // GPS 정확도 미달이지만 그나마 최선
      await saveLastKnown(gpsCandidate.position);
      return LocationResult(
          position: gpsCandidate.position,
          status: LocationStatus.granted,
          step: LocationStep.gps,
          accuracy: gpsCandidate.accuracy);
    } catch (_) {}

    // 2단계: 이전 세션 위치
    final last = await loadLastKnown();
    if (last != null) {
      return LocationResult(
          position: last,
          status: LocationStatus.granted,
          step: LocationStep.lastKnown);
    }

    // 3단계: 네트워크 유추
    try {
      final netPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3),
      );
      final netResult = LatLng(netPos.latitude, netPos.longitude);
      await saveLastKnown(netResult);
      return LocationResult(
          position: netResult,
          status: LocationStatus.granted,
          step: LocationStep.network,
          accuracy: netPos.accuracy);
    } catch (_) {}

    // 4단계: 수동 (사용자가 지도 커서 이동)
    return const LocationResult(
        position: AppConstants.defaultLocation,
        status: LocationStatus.granted,
        step: LocationStep.manual);
  }

  // ── 연속 위치 추적 스트림 ────────────────────────────────────────────────────

  Stream<LatLng> get locationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // 20m 이상 이동 시에만 이벤트 발생
      ),
    )
        .where((pos) => pos.accuracy <= 50.0)
        .map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
