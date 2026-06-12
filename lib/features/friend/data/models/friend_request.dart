import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'friend_duration.dart';

class FriendRequest {
  final String id;
  final String requesterId;
  final LatLng requesterLocation;
  final DateTime createdAt;
  final DateTime expiresAt;
  final FriendDuration duration;
  final FriendDuration? acceptorDuration; // B가 선택한 기간
  final String? responseCode; // B가 기간 선택 후 생성하는 1회용 2자리 코드

  const FriendRequest({
    required this.id,
    required this.requesterId,
    required this.requesterLocation,
    required this.createdAt,
    required this.expiresAt,
    required this.duration,
    this.acceptorDuration,
    this.responseCode,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FriendRequest copyWith({
    FriendDuration? acceptorDuration,
    String? responseCode,
  }) =>
      FriendRequest(
        id: id,
        requesterId: requesterId,
        requesterLocation: requesterLocation,
        createdAt: createdAt,
        expiresAt: expiresAt,
        duration: duration,
        acceptorDuration: acceptorDuration ?? this.acceptorDuration,
        responseCode: responseCode ?? this.responseCode,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterId': requesterId,
        'lat': requesterLocation.latitude,
        'lng': requesterLocation.longitude,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'duration': duration.name,
        'acceptorDuration': acceptorDuration?.name,
        'responseCode': responseCode,
      };

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        id: j['id'] as String,
        requesterId: j['requesterId'] as String,
        requesterLocation: LatLng(
          (j['lat'] as num).toDouble(),
          (j['lng'] as num).toDouble(),
        ),
        createdAt: DateTime.parse(j['createdAt'] as String),
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        duration: FriendDuration.values.byName(j['duration'] as String),
        acceptorDuration: j['acceptorDuration'] != null
            ? FriendDuration.values.byName(j['acceptorDuration'] as String)
            : null,
        responseCode: j['responseCode'] as String?,
      );

  static List<FriendRequest> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<FriendRequest> requests) =>
      jsonEncode(requests.map((r) => r.toJson()).toList());
}
