import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 여러 화면이 함께 쓰는 공용 버튼.
/// 상태(기본 / 통신 중 / 비활성)와 너비는 밖에서 전달받아 "표시만" 합니다.
/// 상태를 바꾸는 결정은 ViewModel이 담당합니다.
///
/// - [onPressed]가 null → 비활성
/// - [isLoading]이 true → onPressed와 관계없이 비활성 + 가운데 로딩 표시
/// - [width]: null = 내용 기반 크기 / double.infinity = 부모 최대 너비 / 숫자 = 고정 크기
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray,
          disabledForegroundColor: AppColors.white,
          // 앱 테마의 minimumSize(전체 너비)를 덮어써서
          // width가 null일 때 Row 안에서도 내용 크기만 쓰도록 합니다.
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 통신 중에는 글자와 인디케이터 중 하나만 그립니다.
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
