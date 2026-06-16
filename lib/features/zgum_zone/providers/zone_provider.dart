import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zgum_zone.dart';
import '../services/zone_detection_service.dart';

final zoneDetectionServiceProvider = Provider((_) => ZoneDetectionService());

/// 현재 진입한 Zone. null = 일반 모드.
final activeZoneProvider = StateProvider<ZGumZone?>((ref) => null);

/// Zone 안에 있는지 여부.
final isInZoneProvider = Provider<bool>(
  (ref) => ref.watch(activeZoneProvider) != null,
);

/// 이 기기가 Hub(중심 단말기) 모드인지 여부.
final isHubModeProvider = StateProvider<bool>((ref) => false);
