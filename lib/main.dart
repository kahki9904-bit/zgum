import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'firebase/firebase_push_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

const _resetPopupHistory = bool.fromEnvironment('ZGUM_RESET_POPUP_HISTORY');
const _popupHistoryKeys = [
  'promo_fu_intro_shown',
  'camera_chooser_popup_shown',
  'partner_intro_shown',
  'ieum_intro_shown',
  'trace_intro_shown',
];

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _resetPopupHistoryForDebug();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    unawaited(FirebasePushService.instance.registerDeviceToken(uid));
  }

  unawaited(FirebasePushService.init());

  runApp(const ProviderScope(child: ZGumApp()));
  unawaited(NotificationService.instance.init());
}

Future<void> _resetPopupHistoryForDebug() async {
  if (!_resetPopupHistory) return;

  final prefs = await SharedPreferences.getInstance();
  for (final key in _popupHistoryKeys) {
    await prefs.remove(key);
  }
}
