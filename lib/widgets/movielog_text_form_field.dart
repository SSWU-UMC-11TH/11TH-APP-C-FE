import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 회원가입 화면의 입력창들이 함께 쓰는 공통 TextFormField.
/// [isPassword]가 true면 오른쪽에 비밀번호 표시·숨김 버튼이 생깁니다.
class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hint,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.isPassword = false,
    this.errorText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;

  /// 서버 검증 결과처럼 validator 밖에서 정해지는 에러 문구.
  /// null이 아니면 validator가 통과해도 입력창이 빨간 에러 상태로 보입니다.
  final String? errorText;

  /// 입력창 오른쪽 아이콘 (비밀번호 칸이 아닐 때만 사용)
  final Widget? suffixIcon;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  // 비밀번호 칸은 처음엔 가려진 상태로 시작합니다.
  bool _obscured = true;

  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.isPassword && _obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      // 한 번 입력을 시작하면 그 칸은 입력할 때마다 바로 검증합니다.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: Icon(widget.prefixIcon),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _obscured ? '비밀번호 보기' : '비밀번호 숨기기',
              )
            : widget.suffixIcon,
        enabledBorder: _border(AppColors.inputBorder),
        focusedBorder: _border(AppColors.primary, 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 2),
      ),
    );
  }
}
