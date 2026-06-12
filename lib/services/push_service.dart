abstract class PushService {
  Future<void> registerDeviceToken(String userId);
  Stream<String> get paymentStatusUpdates;  // orderId 전달
  Stream<String> get traceStatusUpdates;    // traceId 전달
  Stream<void>   get friendNearby;
  Stream<String> get partnerEventNearby;    // eventId 전달
  void dispose();
}
