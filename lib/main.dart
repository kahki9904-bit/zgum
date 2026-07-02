import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers/email_recovery_provider.dart';
import 'core/utils/deep_link_notifier.dart';
import 'firebase/firebase_friend_repository.dart';
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
  'map_marker_intro_shown',
  'email_recovery_popup_shown',
];

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Flutter 라우팅으로 들어오는 Firebase 이메일 링크를 가로채서 처리
class _FirebaseLinkObserver extends WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final path = routeInformation.uri.toString();
    if (!path.contains('oobCode')) return false;

    final Uri fullUri;
    if (routeInformation.uri.hasScheme) {
      fullUri = routeInformation.uri;
    } else {
      fullUri = Uri.parse('https://zgum-6cc66.web.app$path');
    }
    unawaited(_handleDeepLink(fullUri));
    return true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(_FirebaseLinkObserver());
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
    unawaited(FirebaseFriendRepository().removeExpiredFriends(uid));
  }

  unawaited(FirebasePushService.init());
  _initDeepLinks();

  runApp(const ProviderScope(child: ZGumApp()));
  unawaited(NotificationService.instance.init());
}

void _initDeepLinks() {
  final appLinks = AppLinks();

  // 앱을 직접 실행시킨 링크 처리 (cold start)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) _handleDeepLink(uri);
  });

  // 앱 실행 중 수신된 링크 처리
  appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
}

Future<void> _handleDeepLink(Uri uri) async {
  String link = uri.toString();
  if (uri.scheme == 'com.zgum.app') {
    final encoded = uri.queryParameters['link'];
    if (encoded == null) return;
    final continueUri = Uri.tryParse(encoded);
    if (continueUri == null) return;
    final nestedLink = continueUri.queryParameters['link'];
    link = nestedLink ?? continueUri.toString();
  } else if (uri.scheme == 'https' &&
      (uri.host.contains('firebaseapp.com') || uri.host.contains('web.app'))) {
    // oobCode가 최상위에 없을 때만 nested link 추출
    if (uri.queryParameters['oobCode'] == null) {
      final nestedLink = uri.queryParameters['link'];
      if (nestedLink != null) link = nestedLink;
    }
  }

  if (!FirebaseAuth.instance.isSignInWithEmailLink(link)) return;

  final prefs = await SharedPreferences.getInstance();

  // 복구 대기 중인 이메일이 있으면 — 링크만 저장하고 사용자 확인 대기
  final recoveryEmail = prefs.getString('email_recovery_recovery_address');
  if (recoveryEmail != null) {
    await prefs.setString('email_recovery_recovery_link', link);
    emailRecoveryConfirmationController.add(recoveryEmail);
    return;
  }

  // 등록 대기 중인 이메일이 있으면 등록 처리
  final registerEmail = prefs.getString('email_recovery_register_pending');
  final isPending = prefs.getBool('email_recovery_pending') ?? false;
  if (registerEmail != null && isPending) {
    try {
      final credential = EmailAuthProvider.credentialWithLink(
        email: registerEmail,
        emailLink: link,
      );
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      await prefs.setString('email_recovery_address', registerEmail); // 완료 후 메인 키에 저장
      await prefs.remove('email_recovery_register_pending');
      await prefs.setBool('email_recovery_pending', false);
      await writeActiveDevice(registerEmail);
      emailAuthCompletedController.add(null);
    } catch (e) {
      final code = (e as FirebaseAuthException?)?.code;
      if (code == 'provider-already-linked') {
        await prefs.setString('email_recovery_address', registerEmail);
        await prefs.remove('email_recovery_register_pending');
        await prefs.setBool('email_recovery_pending', false);
        await writeActiveDevice(registerEmail);
        emailAuthCompletedController.add(null);
      } else if (code == 'credential-already-in-use' || code == 'email-already-in-use') {
        await prefs.remove('email_recovery_register_pending');
        await prefs.remove('email_recovery_pending');
        emailAuthErrorController.add('already-registered');
      } else {
        await prefs.remove('email_recovery_register_pending');
        await prefs.remove('email_recovery_pending');
      }
    }
  }
}

Future<void> _resetPopupHistoryForDebug() async {
  if (!_resetPopupHistory) return;

  final prefs = await SharedPreferences.getInstance();
  for (final key in _popupHistoryKeys) {
    await prefs.remove(key);
  }
}
