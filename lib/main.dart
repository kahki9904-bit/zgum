import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'app.dart';
import 'core/app_config.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (AppConfig.hasKakaoNativeAppKey) {
    try {
      await KakaoMapSdk.instance.initialize(AppConfig.kakaoNativeAppKey);
    } catch (error) {
      debugPrint('Kakao map initialize failed: $error');
    }
  } else {
    debugPrint('KAKAO_NATIVE_APP_KEY is missing. Kakao map init skipped.');
  }

  runApp(const ProviderScope(child: ZGumApp()));
  unawaited(NotificationService.instance.init());
}
