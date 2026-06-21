// FCM 연동 포인트: firebase_messaging 패키지
// 전환 시: server_transition_providers.dart 에서 MockPushService → FirebasePushService 교체
import '../services/push_service.dart';

class FirebasePushService implements PushService {
  @override
  Future<void> registerDeviceToken(String userId) =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  Stream<String> get paymentStatusUpdates =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  Stream<String> get traceStatusUpdates =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  Stream<void> get friendNearby =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  Stream<String> get partnerEventNearby =>
      throw UnimplementedError('FCM 연동 후 구현');

  @override
  void dispose() {}
}
