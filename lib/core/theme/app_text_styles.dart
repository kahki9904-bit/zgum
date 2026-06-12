import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── 헤드라인 ────────────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDark,
    letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    letterSpacing: -0.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );

  // ── 제목 (섹션·카드 상단) ──────────────────────────────────────────────────
  static const TextStyle titleLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );
  static const TextStyle titleMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
  );
  static const TextStyle titleSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
  );

  // ── 본문 ────────────────────────────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodySub = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSub,
  );

  // ── 캡션·라벨 ───────────────────────────────────────────────────────────────
  static const TextStyle labelLg = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
  static const TextStyle labelStrong = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMid,
  );

  // ── 버튼 ────────────────────────────────────────────────────────────────────
  static const TextStyle buttonLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const TextStyle buttonMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const TextStyle buttonSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── 힌트·비활성 ─────────────────────────────────────────────────────────────
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
  static const TextStyle hintSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // ── 앱바 ────────────────────────────────────────────────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
    letterSpacing: -0.3,
  );
}
