import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  // Android 13+ 알림 권한 요청 — true: 허용됨, false: 거부됨
  Future<bool> requestPermission() async {
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
    await _plugin.cancel(eventId.hashCode.abs() % 100000);
  }
}
