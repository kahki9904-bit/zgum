import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await KakaoMapSdk.instance.initialize('8afda6d12588ca6c501beef9e41136f8');
  } catch (_) {}

  runApp(const ProviderScope(child: ZGumApp()));
  unawaited(NotificationService.instance.init());
}
