import 'dart:math';
import 'package:latlong2/latlong.dart';

/// 두 좌표 사이의 나침반 방향 (8방향 한국어).
String directionLabel(LatLng from, LatLng to) {
  final lat1 = from.latitude * pi / 180;
  final lat2 = to.latitude * pi / 180;
  final dLon = (to.longitude - from.longitude) * pi / 180;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  final bearing = (atan2(y, x) * 180 / pi + 360) % 360;
  const dirs = ['북', '북동', '동', '남동', '남', '남서', '서', '북서'];
  return dirs[((bearing + 22.5) / 45).floor() % 8];
}

/// 두 좌표 사이의 직선 거리 (Haversine 공식, 단위: km)
double haversineKm(LatLng from, LatLng to) {
  const r = 6371.0;
  final dLat = (to.latitude - from.latitude) * pi / 180;
  final dLon = (to.longitude - from.longitude) * pi / 180;
  final lat1 = from.latitude * pi / 180;
  final lat2 = to.latitude * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// 평균 도보 속도 4 km/h 기준 소요 시간(분). 최소 1분.
int walkingMinutes(LatLng from, LatLng to) =>
    max(1, (haversineKm(from, to) / 4.0 * 60).round());
