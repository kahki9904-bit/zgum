import 'dart:async';
import '../services/push_service.dart';

class MockPushService implements PushService {
  final _payment = StreamController<String>.broadcast();
  final _trace   = StreamController<String>.broadcast();
  final _friend  = StreamController<void>.broadcast();
  final _partner = StreamController<String>.broadcast();

  @override
  Future<void> registerDeviceToken(String userId) async {}

  @override
  Stream<String> get paymentStatusUpdates => _payment.stream;

  @override
  Stream<String> get traceStatusUpdates => _trace.stream;

  @override
  Stream<void> get friendNearby => _friend.stream;

  @override
  Stream<String> get partnerEventNearby => _partner.stream;

  @override
  void dispose() {
    _payment.close();
    _trace.close();
    _friend.close();
    _partner.close();
  }
}
