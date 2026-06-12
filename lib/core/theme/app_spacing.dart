import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── 기본 간격 단위 ───────────────────────────────────────────────────────────
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double x3l = 32.0;

  // ── 페이지 공통 여백 ─────────────────────────────────────────────────────────
  /// 좌우 기본 페이지 패딩 (horizontal: 20)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: xl);

  /// 좌우 넓은 페이지 패딩 (horizontal: 24)
  static const EdgeInsets pagePaddingWide = EdgeInsets.symmetric(horizontal: xxl);

  /// 카드 내부 패딩
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  // ── 칩·배지 패딩 ────────────────────────────────────────────────────────────
  /// 칩 기본 패딩 (horizontal: 8, vertical: 4)
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: sm, vertical: xs);

  /// 칩 넓은 패딩 (horizontal: 12, vertical: 6)
  static const EdgeInsets chipPaddingWide = EdgeInsets.symmetric(horizontal: md, vertical: 6);

  // ── 버튼 패딩 ───────────────────────────────────────────────────────────────
  /// 기본 버튼 패딩
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: md);

  /// 아이콘 버튼 패딩 (좁게)
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  // ── 리스트 아이템 ────────────────────────────────────────────────────────────
  /// 리스트 아이템 세로 패딩
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(vertical: md);

  /// 리스트 아이템 넓은 세로 패딩
  static const EdgeInsets listItemPaddingWide = EdgeInsets.symmetric(vertical: 14);

  // ── SizedBox 공통 간격 ───────────────────────────────────────────────────────
  static const SizedBox gapXs  = SizedBox(height: xs);
  static const SizedBox gapSm  = SizedBox(height: sm);
  static const SizedBox gapMd  = SizedBox(height: md);
  static const SizedBox gapLg  = SizedBox(height: lg);
  static const SizedBox gapXl  = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  static const SizedBox hGapXs  = SizedBox(width: xs);
  static const SizedBox hGapSm  = SizedBox(width: sm);
  static const SizedBox hGapMd  = SizedBox(width: md);
  static const SizedBox hGapLg  = SizedBox(width: lg);
  static const SizedBox hGapXl  = SizedBox(width: xl);
}
