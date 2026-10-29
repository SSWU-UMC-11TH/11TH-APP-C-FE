import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전체에서 반복해서 쓰는 글자 스타일.
/// 화면에서는 TextStyle을 직접 만들지 않고 여기 정의한 값을 쓰고,
/// 일부만 바꿀 때는 copyWith를 사용합니다.
abstract final class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.black,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: AppColors.black,
  );

  static const bodyMedium = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.black,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.gray,
  );

  static const statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
