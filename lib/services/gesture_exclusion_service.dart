import 'package:flutter/services.dart';

/// Android Q(10)+ 에서 시스템 백(back) 제스처 영역을 제외시킵니다.
/// 지도 화면처럼 WebView가 화면을 가득 채워 엣지 스와이프가 OS에 가로채일 때 사용합니다.
class GestureExclusionService {
  static const _ch = MethodChannel('com.example.zgum/gesture');

  /// [rects] 의 영역을 Android 시스템 백 제스처에서 제외합니다.
  /// [devicePixelRatio] 는 논리 좌표를 물리 픽셀로 변환하는 배율입니다.
  static Future<void> setExclusionRects(
    List<Rect> rects,
    double devicePixelRatio,
  ) async {
    await _ch.invokeMethod<void>('setExclusionRects', {
      'rects': rects
          .map((r) => {
                'left': (r.left * devicePixelRatio).round(),
                'top': (r.top * devicePixelRatio).round(),
                'right': (r.right * devicePixelRatio).round(),
                'bottom': (r.bottom * devicePixelRatio).round(),
              })
          .toList(),
    });
  }

  /// 등록된 제외 영역을 모두 해제합니다.
  static Future<void> clearExclusionRects() async {
    await _ch.invokeMethod<void>('clearExclusionRects');
  }
}
