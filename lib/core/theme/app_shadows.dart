import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  /// 카드·팝업·바텀시트 기본 그림자
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// 검색 패널·가벼운 컴포넌트 그림자
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// 필터바·작은 플로팅 버튼 그림자
  static const List<BoxShadow> float = [
    BoxShadow(
      color: AppColors.barrierLight,
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// 지도 마커 그림자
  static const List<BoxShadow> marker = [
    BoxShadow(
      color: AppColors.shadowMarker,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// 플로팅 버튼 (지도 위 버튼 등)
  static const List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
