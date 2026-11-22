import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [8주차] 로그인·프로필 수정 화면의 입력칸 위 라벨. (Figma W8-03 · W8-07)
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

OutlineInputBorder _inputBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}

/// [8주차] 로그인·프로필 수정 화면이 함께 쓰는 입력칸 모양.
///
/// - 기본: 흰 배경 + 옅은 테두리
/// - [hasError]: 서버가 거부한 값처럼 errorText 없이도 붉은 테두리를 보여줄 때
/// - [readOnly]: 이메일처럼 바꿀 수 없는 값 (회색 배경)
InputDecoration movieLogInputDecoration({
  String? hintText,
  String? errorText,
  bool hasError = false,
  bool readOnly = false,
}) {
  final normal = hasError ? AppColors.danger : AppColors.cardBorder;
  final focused = hasError ? AppColors.danger : AppColors.violet;

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSub),
    errorText: errorText,
    errorMaxLines: 2,
    isDense: true,
    filled: true,
    fillColor: readOnly ? AppColors.chip : AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: _inputBorder(normal),
    enabledBorder: _inputBorder(normal),
    disabledBorder: _inputBorder(readOnly ? AppColors.chip : normal),
    focusedBorder: _inputBorder(focused),
    errorBorder: _inputBorder(AppColors.danger),
    focusedErrorBorder: _inputBorder(AppColors.danger),
  );
}
