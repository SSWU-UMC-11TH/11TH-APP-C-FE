import 'package:flutter/material.dart';

/// Figma 시안에서 가져온 색상.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF65509F);
  static const Color background = Color(0xFFFAF8F5);

  /// 선택 표시, 선호 장르 Chip
  static const Color lavender = Color(0xFFE9DFF7);

  /// 마이페이지 통계 박스
  static const Color lavenderLight = Color(0xFFF1ECF9);

  /// 선택되지 않은 Chip, 태그
  static const Color chip = Color(0xFFE6E1EA);
  static const Color textSub = Color(0xFF6B6770);
  static const Color divider = Color(0xFFE3DFE6);

  /// 채워지지 않은 별
  static const Color starOff = Color(0xFFDDD8EA);

  /// [6주차] 공용 버튼(MovieLogButton)의 기본 배경
  static const Color violet = primary;

  /// [6주차] 공용 버튼의 통신 중·비활성 배경
  static const Color gray = Color(0xFFB9B5BF);
  static const Color white = Color(0xFFFFFFFF);
}

/// [6주차] 여러 화면이 함께 쓰는 글자 스타일.
class AppTextStyles {
  AppTextStyles._();

  /// 입력창 아래 안내 문구처럼 작은 보조 텍스트
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textSub,
  );
}

/// 모든 화면이 공유하는 Material 3 Theme.
class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    // pubspec.yaml에 Manrope가 등록되어 있지 않으면 기본 글꼴로 표시된다.
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.lavender,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}