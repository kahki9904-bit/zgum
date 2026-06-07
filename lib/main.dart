import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'app.dart';
import 'core/app_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await NotificationService.instance.init();

  if (AppConfig.hasKakaoKey) {
    AuthRepository.initialize(
      appKey: AppConfig.kakaoApiKey,
      baseUrl: 'http://localhost',
    );
  }

  runApp(const ProviderScope(child: ZGumApp()));
}
