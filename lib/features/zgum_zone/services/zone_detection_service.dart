import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zgum_zone.dart';

// SharedPreferences 키 (Firebase 전환 시 Firestore 경로로 교체)
const _kHubActive  = 'zgum_hub_active';
const _kHubLat     = 'zgum_hub_lat';
const _kHubLng     = 'zgum_hub_lng';
const _kHubRadiusM = 'zgum_hub_radius_m';
const _kHubName    = 'zgum_hub_name';

class ZoneDetectionService {
  // GPS 고정 구역 목록 — Firebase 연동 후 서버에서 받아옴
  static const List<ZGumZone> _gpsZones = [];

  /// 현재 위치 기준으로 진입한 Zone 반환. 없으면 null.
  Future<ZGumZone?> detectZone(double userLat, double userLng) async {
    // 1. GPS 고정 구역 검사
    for (final zone in _gpsZones) {
      final dist = Geolocator.distanceBetween(
        userLat, userLng, zone.centerLat, zone.centerLng,
      );
      if (dist <= zone.radiusM) return zone;
    }

    // 2. 중심 단말기 구역 검사
    return _detectHubZone(userLat, userLng);
  }

  Future<ZGumZone?> _detectHubZone(double userLat, double userLng) async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_kHubActive) ?? false;
    if (!active) return null;

    final lat    = prefs.getDouble(_kHubLat);
    final lng    = prefs.getDouble(_kHubLng);
    final radius = prefs.getDouble(_kHubRadiusM);
    final name   = prefs.getString(_kHubName) ?? 'Z:GIM ZONE';
    if (lat == null || lng == null || radius == null) return null;

    final dist = Geolocator.distanceBetween(userLat, userLng, lat, lng);
    if (dist > radius) return null;

    return ZGumZone(
      id: 'hub',
      name: name,
      centerLat: lat,
      centerLng: lng,
      radiusM: radius,
      type: ZoneType.hubDevice,
    );
  }

  // ── Hub 모드 (중심 단말기) ──────────────────────────────────────────────

  /// 이 기기를 Zone 중심으로 등록.
  /// Firebase 전환 시 Firestore write로 교체.
  Future<void> startHubMode({
    required double lat,
    required double lng,
    required double radiusM,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHubActive, true);
    await prefs.setDouble(_kHubLat, lat);
    await prefs.setDouble(_kHubLng, lng);
    await prefs.setDouble(_kHubRadiusM, radiusM);
    await prefs.setString(_kHubName, name);
  }

  /// Hub 모드 종료.
  Future<void> stopHubMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHubActive, false);
  }

  /// Hub 기기가 이동했을 때 위치 갱신.
  Future<void> updateHubLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kHubActive) ?? false)) return;
    await prefs.setDouble(_kHubLat, lat);
    await prefs.setDouble(_kHubLng, lng);
  }

  Future<bool> isHubActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHubActive) ?? false;
  }
}
