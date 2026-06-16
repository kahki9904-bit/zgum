enum ZoneType {
  gps,       // 고정 GPS 좌표 기반 구역
  hubDevice, // 중심 단말기 위치 기반 구역
}

class ZGumZone {
  final String id;
  final String name;
  final double centerLat;
  final double centerLng;
  final double radiusM;
  final ZoneType type;

  const ZGumZone({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.radiusM,
    required this.type,
  });
}
