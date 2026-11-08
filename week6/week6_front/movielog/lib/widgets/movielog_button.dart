import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [6주차] 여러 화면이 함께 쓰는 공용 버튼.
///
/// 버튼은 상태를 "표시"만 하고 스스로 바꾸지 않는다.
/// 지금 통신 중인지(isLoading), 누를 수 있는지(onPressed), 너비를 얼마나 쓸지(width)는
/// View가 ViewModel의 상태를 보고 전달한다.
///
/// - 기본: onPressed가 있고 isLoading이 false
/// - 통신 중: isLoading이 true → 회색 배경 + 가운데 인디케이터만 표시, 누를 수 없음
/// - 비활성: onPressed가 null → 회색 배경, 누를 수 없음
///
/// width
/// - null: 내용(label) 길이에 맞는 크기 (입력창 옆 보조 버튼)
/// - double.infinity: 부모가 허용하는 최대 너비 (Form 아래 제출 버튼)
/// - 고정 값: 항상 같은 크기
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
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.gray,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 통신 중에는 label과 인디케이터 중 하나만 그린다.
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
