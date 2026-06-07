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
  final String? responseToken; // B가 수락 시 생성, A에게 구두로 알려줌

  const FriendRequest({
    required this.id,
    required this.requesterId,
    required this.requesterLocation,
    required this.createdAt,
    required this.expiresAt,
    required this.duration,
    this.responseToken,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FriendRequest copyWith({String? responseToken}) => FriendRequest(
        id: id,
        requesterId: requesterId,
        requesterLocation: requesterLocation,
        createdAt: createdAt,
        expiresAt: expiresAt,
        duration: duration,
        responseToken: responseToken ?? this.responseToken,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterId': requesterId,
        'lat': requesterLocation.latitude,
        'lng': requesterLocation.longitude,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'duration': duration.name,
        'responseToken': responseToken,
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
        responseToken: j['responseToken'] as String?,
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
