import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 지도 마커에 표시할 텍스트 배지 비트맵을 생성하고 캐싱합니다.
///
/// ## 마커 형태
/// ```
/// ┌──────────────────┐  ← 둥근 사각형 배지 (색상 채움)
/// │   도보 8분        │  ← 흰색 굵은 텍스트
/// └─────────┬────────┘
///           ▼          ← 삼각형 핀 팁 (위치 앵커)
/// ```
/// `Marker.anchor = Offset(0.5, 1.0)` 이 기본값과 일치하도록
/// 삼각형 팁이 이미지 정확히 하단 중앙에 위치합니다.
///
/// ## 캐싱 전략
/// (color, label) 조합을 키로 정적 캐싱합니다.
/// 동일 조합은 첫 렌더링 이후 즉시 반환되어 반복 GPU 비용이 없습니다.
///
/// ## DPR 독립 크기 처리
/// 내부 렌더링은 [_kPxRatio]배 해상도로 수행하고,
/// [BitmapDescriptor.bytes]의 `size` 파라미터로 논리 픽셀 크기를 고정합니다.
/// 어느 화면 밀도에서도 동일한 논리 크기로 표시됩니다.
class MarkerBitmapFactory {
  MarkerBitmapFactory._();

  static final Map<int, Uint8List> _cache = {};

  // ── 디자인 상수 (논리 픽셀 기준) ─────────────────────────────────────────
  static const double _kBadgeW = 72.0; // 한국어 최장 레이블 "도보 20분" 수용
  static const double _kBadgeH = 22.0;
  static const double _kTipH = 10.0;   // 삼각형 핀 높이
  static const double _kCornerR = 7.0;
  static const double _kPxRatio = 3.0; // 고해상도 렌더링 배율

  /// 텍스트 배지 마커를 반환합니다.
  ///
  /// - [pinColor]: 배지 배경 색상
  /// - [label]: 배지 안에 표시할 텍스트 (예: '도보 8분', '마감')
  /// PNG 바이트를 반환합니다. Kakao Maps 마커 커스텀 이미지로 사용 예정.
  static Future<Uint8List> create({
    required Color pinColor,
    required String label,
  }) async {
    final key = Object.hashAll([pinColor.toARGB32(), label]);
    final cached = _cache[key];
    if (cached != null) return cached;

    final bytes = await _renderPng(color: pinColor, label: label);
    _cache[key] = bytes;
    return bytes;
  }

  /// 캐시를 초기화합니다 (테마·언어 변경 시 호출).
  static void clearCache() => _cache.clear();

  // ── 내부 렌더링 ───────────────────────────────────────────────────────────

  static Future<Uint8List> _renderPng({
    required Color color,
    required String label,
  }) async {
    const r = _kPxRatio;
    const logW = _kBadgeW;
    const logH = _kBadgeH + _kTipH;

    final pxW = (logW * r).ceil();
    final pxH = (logH * r).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
    );
    canvas.scale(r, r);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── 배지 배경 ──────────────────────────────────────────────────────────
    final badgeRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, logW, _kBadgeH),
      const Radius.circular(_kCornerR),
    );
    canvas.drawRRect(badgeRRect, fill);

    // 가독성을 높이는 미세 외곽선
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.5, 0.5, logW - 1, _kBadgeH - 1),
        const Radius.circular(_kCornerR - 0.5),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 삼각형 핀 팁 ─────────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(logW / 2 - 7, _kBadgeH)
        ..lineTo(logW / 2 + 7, _kBadgeH)
        ..lineTo(logW / 2, logH) // ← 이미지 하단 중앙 = Marker anchor(0.5, 1.0)
        ..close(),
      fill,
    );

    // ── 텍스트 ────────────────────────────────────────────────────────────
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: logW);

    tp.paint(
      canvas,
      Offset(
        (logW - tp.width) / 2,
        (_kBadgeH - tp.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(pxW, pxH);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();
    return bd!.buffer.asUint8List();
  }
}
