import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱 전역 1초 시계. 지도 마커·패널 목록의 소멸 애니메이션 동기화에 사용.
final tickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
