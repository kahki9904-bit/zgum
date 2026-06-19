import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  // Android 13+ 알림 권한 요청 — true: 허용됨, false: 거부됨
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  // 이벤트 알림 예약 — eventId를 알림 ID로 사용 (중복 방지)
  Future<void> scheduleEventAlarm({
    required String eventId,
    required String eventTitle,
    required DateTime notifyAt,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      eventId.hashCode.abs() % 100000,
      'Z:GUM',
      '$eventTitle — 곧 종료됩니다',
      tz.TZDateTime.from(notifyAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zgum_event_alarm',
          '이벤트 알림',
          channelDescription: '사용자가 지정한 이벤트 종료 전 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 이벤트 알림 취소
  Future<void> cancelEventAlarm(String eventId) async {
    await init();
    await _plugin.cancel(eventId.hashCode.abs() % 100000);
  }

  // 친구 근접 알림 — 즉시 표시
  Future<void> showFriendNearbyNotification() async {
    await init();
    await _plugin.show(
      900001,
      'Z:GUM',
      '친구가 근처에 있어요. 찾아볼까요?',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zgum_friend_nearby',
          '친구 근접 알림',
          channelDescription: '친구탐험 — 근처에 있는 친구 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // 친구 등록 완료 알림
  Future<void> showFriendRegisteredNotification() async {
    await init();
    await _plugin.show(
      900002,
      'Z:GUM',
      '친구 등록이 완료됐어요.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zgum_friend_registered',
          '친구 등록 알림',
          channelDescription: '친구 등록 완료 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  // 만료 예정 친구 알림
  Future<void> showFriendExpiryNotification() async {
    await init();
    await _plugin.show(
      900003,
      'Z:GUM',
      '곧 만남이 끊길 친구가 있어요. 다시 만나서 이어가세요.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zgum_friend_expiry',
          '친구 만료 예정 알림',
          channelDescription: '친구 연결이 곧 만료되는 경우 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
