import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/notification_service.dart';
import '../data/repositories/friend_repository.dart';

class FriendProximityService {
  final FriendRepository repo;

  static const Duration expiryWarningThreshold = Duration(days: 3);
  static const Duration presenceStaleDuration = Duration(minutes: 30);

  const FriendProximityService(this.repo);

  // 내 현재 위치를 Firestore presence 컬렉션에 기록
  static Future<void> recordPresence(String userId, LatLng location) async {
    try {
      await FirebaseFirestore.instance.collection('presence').doc(userId).set({
        'lat': location.latitude,
        'lng': location.longitude,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // presence 기록 실패는 무시
    }
  }

  // 이음 상대방 위치 확인 후 100m 이내면 기간 갱신 + 알림
  Future<void> checkAndRenewNearbyFriends({
    required String myUserId,
    required LatLng myLocation,
  }) async {
    try {
      final friends = await repo.getActiveFriends(myUserId);
      if (friends.isEmpty) return;

      const calc = Distance();
      final now = DateTime.now();

      for (final friend in friends) {
        try {
          final presenceDoc = await FirebaseFirestore.instance
              .collection('presence')
              .doc(friend.friendUserId)
              .get();
          if (!presenceDoc.exists) continue;

          final data = presenceDoc.data()!;
          final updatedAt =
              (data['updatedAt'] as Timestamp).toDate();
          if (now.difference(updatedAt) > presenceStaleDuration) continue;

          final friendLocation = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          );
          final dist = calc.as(
            LengthUnit.Meter,
            myLocation,
            friendLocation,
          );

          if (dist <= FriendRepository.proximityMeters && friend.canNotify) {
            final originalDuration =
                friend.expiresAt.difference(friend.createdAt);
            final newExpiry = now.add(originalDuration);
            await repo.renewFriend(friend.id, newExpiry);
            await repo.recordNotification(friend.id);
            await NotificationService.instance.showFriendNearbyNotification();
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
  }

  // 만료 예정 친구 확인 — 앱 시작 또는 화면 진입 시 호출
  Future<bool> checkExpiringFriends(String myUserId) async {
    final friends = await repo.getActiveFriends(myUserId);
    final now = DateTime.now();
    final hasExpiring = friends.any(
      (f) => f.expiresAt.difference(now) <= expiryWarningThreshold,
    );
    if (hasExpiring) {
      await NotificationService.instance.showFriendExpiryNotification();
    }
    return hasExpiring;
  }
}
