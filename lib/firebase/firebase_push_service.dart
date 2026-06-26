import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class FirebasePushService implements PushService {
  FirebasePushService._();
  static final FirebasePushService instance = FirebasePushService._();
  factory FirebasePushService() => instance;

  final _fcm = FirebaseMessaging.instance;
  final _nearbyCtrl = StreamController<void>.broadcast();
  final _partnerEventCtrl = StreamController<String>.broadcast();
  final _paymentCtrl = StreamController<String>.broadcast();
  final _traceCtrl = StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _fgSub;

  static Future<void> init() async => instance._doInit();

  Future<void> _doInit() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    _fgSub = FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleOpen(initial);
  }

  void _handleMessage(RemoteMessage msg) {
    final n = msg.notification;
    if (n != null) {
      NotificationService.instance.showFcmNotification(
        title: n.title ?? 'Z:GUM',
        body: n.body ?? '',
      );
    }
    _dispatch(msg.data);
  }

  void _handleOpen(RemoteMessage msg) => _dispatch(msg.data);

  void _dispatch(Map<String, dynamic> data) {
    switch (data['type'] as String?) {
      case 'friend_nearby':
        _nearbyCtrl.add(null);
      case 'partner_event_nearby':
        _partnerEventCtrl.add(data['eventId'] as String? ?? '');
      case 'payment_update':
        _paymentCtrl.add(data['orderId'] as String? ?? '');
      case 'trace_update':
        _traceCtrl.add(data['traceId'] as String? ?? '');
    }
  }

  @override
  Future<void> registerDeviceToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // APNs 미등록 상태(Apple Developer 승인 전)에서는 무시
    }
  }

  @override
  Stream<void> get friendNearby => _nearbyCtrl.stream;
  @override
  Stream<String> get partnerEventNearby => _partnerEventCtrl.stream;
  @override
  Stream<String> get paymentStatusUpdates => _paymentCtrl.stream;
  @override
  Stream<String> get traceStatusUpdates => _traceCtrl.stream;

  @override
  void dispose() {
    _fgSub?.cancel();
    _nearbyCtrl.close();
    _partnerEventCtrl.close();
    _paymentCtrl.close();
    _traceCtrl.close();
  }
}
