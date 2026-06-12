import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // ── 모서리 반지름 상수 ───────────────────────────────────────────────────────
  static const double xs   = 6.0;   // 작은 배지·태그
  static const double sm   = 8.0;   // 인풋 필드·작은 카드
  static const double md   = 12.0;  // 표준 카드·버튼
  static const double lg   = 16.0;  // 큰 카드
  static const double xl   = 20.0;  // 칩·알림 버튼
  static const double xxl  = 24.0;  // 바텀시트·팝업
  static const double pill = 100.0; // 완전한 알약형

  // ── BorderRadius 바로 사용 가능한 상수 ──────────────────────────────────────
  static const BorderRadius bXs   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius bSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius bMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius bLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius bXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius bXxl  = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius bPill = BorderRadius.all(Radius.circular(pill));

  /// 바텀시트 전용 — 상단만 둥글게
  static const BorderRadius bSheet = BorderRadius.vertical(top: Radius.circular(xxl));

  // ── RoundedRectangleBorder 바로 사용 가능한 상수 ────────────────────────────
  static const RoundedRectangleBorder shapeMd  = RoundedRectangleBorder(borderRadius: bMd);
  static const RoundedRectangleBorder shapeLg  = RoundedRectangleBorder(borderRadius: bLg);
  static const RoundedRectangleBorder shapeXxl = RoundedRectangleBorder(borderRadius: bXxl);
}
