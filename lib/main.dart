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
    await KakaoMapSdk.instance.initialize('433d2724092434b5642227386bcd2f13');
  } catch (_) {}

  runApp(const ProviderScope(child: ZGumApp()));
  unawaited(NotificationService.instance.init());
}
