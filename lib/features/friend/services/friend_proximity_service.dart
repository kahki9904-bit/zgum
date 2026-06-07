import '../../../services/notification_service.dart';
import '../data/models/friend.dart';
import '../data/repositories/friend_repository.dart';

class FriendProximityService {
  final FriendRepository repo;

  // 만료 경고 기준: 3일 전
  static const Duration expiryWarningThreshold = Duration(days: 3);

  const FriendProximityService(this.repo);

  // 실제 모드: Firebase Cloud Function이 서버에서 위치 비교 후 FCM 발송
  // 테스트 모드: 수동 트리거로 알림 동작 확인
  Future<List<Friend>> simulateNearbyAlert({
    required String myUserId,
  }) async {
    final friends = await repo.getActiveFriends(myUserId);
    final notifiable = friends.where((f) => f.canNotify).toList();

    for (final friend in notifiable) {
      await repo.recordNotification(friend.id);
      await NotificationService.instance.showFriendNearbyNotification();
    }
    return notifiable;
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
