import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../constants.dart';

/// 앱 전역 사용자 위치 — GPS 확정 시 map_room_screen 에서 갱신
final userLocationProvider = StateProvider<LatLng>(
  (_) => AppConstants.defaultLocation,
);
