import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── 브랜드 메인 ─────────────────────────────────────────────────────────────
  /// 딥블루 — 버튼·강조·아이콘의 기준색
  static const Color primary = Color(0xFF16213E);

  /// 다크 네이비 — 텍스트·제목의 기준색
  static const Color primaryDark = Color(0xFF1A1A2E);

  // ── 작동 버튼 골드 ─────────────────────────────────────────────────────────
  static const Color actionGold = Color(0xFF5A452D);
  static const Color actionGoldBright = Color(0xFFC9A45A);
  static const Color actionGoldSoft = Color(0xFFF4EBD7);
  static const Color actionGoldBorder = Color(0xFFD9BD7A);
  static const Color actionGoldText = Color(0xFF6D5633);

  // ── 배경 ────────────────────────────────────────────────────────────────────
  static const Color background = Colors.white;
  static const Color surfaceGray = Color(0xFFF4F6FB);
  static const Color surfaceLight = Color(0xFFF4F4F7);
  static const Color inputBg = Color(0xFFF5F5F5);

  // ── 텍스트 ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF333333);
  static const Color textMid = Color(0xFF555555);
  static const Color textSub = Color(0xFF888888);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color textDisabled = Color(0xFFBBBBBB);
  static const Color textHint = Color(0xFFCCCCCC);

  // ── 구분선·테두리 ──────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFF0F0F0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderMid = Color(0xFFDDDDDD);

  // ── 카테고리 마커 색상 ──────────────────────────────────────────────────────
  static const Color catMovie = Color(0xFF1565C0); // 영화
  static const Color catExhibit = Color(0xFFD4AF37); // 전시
  static const Color catConcert = Color(0xFFE74C3C); // 콘서트
  static const Color catPerform = Color(0xFF4ECDC4); // 공연·뮤지컬
  static const Color catFood = Color(0xFFF97316); // 음식·팝업
  static const Color catPartner = Color(0xFFFF8C00); // 파트너 이벤트
  static const Color catOther = Color(0xFF9C27B0); // 기타

  // ── 상태 색상 ───────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFE53935); // 경고·삭제
  static const Color warning = Color(0xFFFF8C00); // 주의
  static const Color success = Color(0xFF27AE60); // 완료·체크인
  static const Color info = Color(0xFF3A5FCD); // 정보

  // ── 그림자·오버레이 ─────────────────────────────────────────────────────────
  static const Color shadowCard = Color(0x38000000); // 블랙 22% — 카드 그림자
  static const Color shadowSoft = Color(0x18000000); // 블랙 9%  — 가벼운 그림자
  static const Color shadowMarker = Color(0x40000000); // 블랙 25% — 마커 그림자
  static const Color barrier = Colors.black54;
  static const Color barrierLight = Colors.black26;
}
