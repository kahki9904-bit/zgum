// Firestore 연동 포인트: 컬렉션 'friend_requests', 'friends/{userId}/connections'
// 전환 시: friend_provider.dart 에서 MockFriendRepository → FirebaseFriendRepository 교체
import 'package:latlong2/latlong.dart';
import '../features/friend/data/models/friend.dart';
import '../features/friend/data/models/friend_duration.dart';
import '../features/friend/data/models/friend_request.dart';
import '../features/friend/data/repositories/friend_repository.dart';

class FirebaseFriendRepository implements FriendRepository {
  @override
  Future<FriendRequest> broadcastRequest({
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<FriendRequest>> getNearbyRequests({
    required LatLng myLocation,
    required String myUserId,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<String?> respondToRequest({
    required String requestId,
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
    bool skipProximityCheck = false,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<Friend?> confirmRequest({
    required String requestId,
    required String responseCode,
    required String myUserId,
    required LatLng myLocation,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<Friend>> getActiveFriends(String userId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> recordNotification(String friendId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> renewFriend(String friendId, DateTime newExpiry) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> removeExpiredFriends(String userId) =>
      throw UnimplementedError('Firestore 연동 후 구현');
}
