import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';

class AppTheme {
  AppTheme._();

  /// 기존 코드 호환용 — AppColors.primary 와 동일
  static const Color deepBlue = AppColors.primary;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primaryDark,
          onSecondary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.primaryDark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: GoogleFonts.notoSansKr().fontFamily,

        textTheme: GoogleFonts.notoSansKrTextTheme(const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          titleMedium: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSub,
            height: 1.6,
          ),
          labelLarge: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        )),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),

        cardTheme: CardThemeData(
          color: AppColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.bLg,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          secondaryLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bXl),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        ),

        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bSheet),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.12),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primary.withValues(alpha: 0.08),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              );
            }
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.primary.withValues(alpha: 0.4),
            );
          }),
          shadowColor: AppColors.primary.withValues(alpha: 0.08),
          elevation: 8,
        ),

        dividerTheme: DividerThemeData(
          color: AppColors.primary.withValues(alpha: 0.08),
          thickness: 1,
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: AppRadius.shapeMd,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  // 다크 테마 (향후 대비)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.notoSansKr().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.catExhibit,
          surface: AppColors.primary,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.primaryDark,
      );
}
