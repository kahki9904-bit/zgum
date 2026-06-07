import 'package:latlong2/latlong.dart';
import '../models/friend.dart';
import '../models/friend_duration.dart';
import '../models/friend_request.dart';

abstract class FriendRepository {
  static const double proximityMeters = 100.0;
  static const double maxAccuracyMeters = 50.0;
  static const Duration notificationCooldown = Duration(hours: 12);
  static const Duration requestTtl = Duration(minutes: 5);

  // A: 신청 브로드캐스트
  Future<FriendRequest> broadcastRequest({
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
  });

  // B: 근처 신청 목록 조회
  Future<List<FriendRequest>> getNearbyRequests({
    required LatLng myLocation,
    required String myUserId,
  });

  // B: 수락 → 코드 생성 → 반환 (B가 A에게 구두로 알려줌)
  Future<String?> respondToRequest({
    required String requestId,
    required String myUserId,
    required LatLng myLocation,
    bool skipProximityCheck = false,
  });

  // A: B의 코드 입력 → 친구 생성
  Future<Friend?> confirmRequest({
    required String requestId,
    required String responseToken,
    required String myUserId,
    required LatLng myLocation,
  });

  Future<List<Friend>> getActiveFriends(String userId);
  Future<void> recordNotification(String friendId);
  Future<void> renewFriend(String friendId, DateTime newExpiry);
  Future<void> removeExpiredFriends(String userId);
}
