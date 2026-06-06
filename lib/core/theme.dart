import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Z:GUM 디자인 정체성 ───────────────────────────────────────────────────────
  // 철학: 화이트 배경 + 딥 블루 포인트 — 여백의 미, 절제된 컬러

  /// 딥 블루 — 앱의 핵심 포인트 컬러
  static const Color deepBlue = Color(0xFF00008B);

  /// 텍스트용 소프트 딥 블루 (너무 진하지 않게 가독성 보완)
  static const Color deepBlueSoft = Color(0xFF1A237E);

  /// 보조 텍스트 — 딥 블루 30% 불투명
  static const Color deepBlueSubtle = Color(0x4D00008B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: deepBlue,
          onPrimary: Colors.white,
          secondary: deepBlueSoft,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: deepBlue,
        ),
        scaffoldBackgroundColor: Colors.white,

        // 텍스트 테마 — 고딕(Sans-serif) 기반
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w300,
          ),
          headlineLarge: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          titleMedium: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: deepBlue,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: deepBlueSoft,
            height: 1.6,
          ),
          labelLarge: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        // NavigationBar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: deepBlue.withValues(alpha: 0.08),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: deepBlue);
            }
            return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: deepBlue.withValues(alpha: 0.4));
          }),
          shadowColor: deepBlue.withValues(alpha: 0.08),
          elevation: 8,
        ),

        // 카드
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: deepBlue.withValues(alpha: 0.08), width: 1),
          ),
        ),

        // 앱바
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: deepBlue,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: deepBlue,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),

        // 칩
        chipTheme: ChipThemeData(
          backgroundColor: deepBlue.withValues(alpha: 0.05),
          selectedColor: deepBlue.withValues(alpha: 0.12),
          labelStyle:
              TextStyle(color: deepBlue.withValues(alpha: 0.7), fontSize: 12),
          secondaryLabelStyle: const TextStyle(
              color: deepBlue, fontSize: 12, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide(color: deepBlue.withValues(alpha: 0.15)),
        ),

        // 바텀 시트
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 0,
          shadowColor: deepBlue.withValues(alpha: 0.12),
        ),

        dividerTheme: DividerThemeData(
          color: deepBlue.withValues(alpha: 0.08),
          thickness: 1,
        ),
      );

  // 다크 테마는 유지 (향후 토글 대비)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          surface: Color(0xFF16213E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      );
}
