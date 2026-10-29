import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_text_form_field.dart';

/// 회원가입 입력값 검증 규칙. validator는 오류면 문구, 통과면 null을 반환합니다.
abstract final class SignUpValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? nickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해주세요.';
    if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해주세요.';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아니에요.';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상 입력해주세요.';
    return null;
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller와 FocusNode는 build가 아닌 State 필드에서 한 번만 만듭니다.
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// 버튼 활성화용 빠른 검사. 최종 검증은 제출할 때 validate()로 다시 합니다.
  bool get _canSubmit =>
      SignUpValidators.nickname(_nicknameController.text) == null &&
      SignUpValidators.email(_emailController.text) == null &&
      SignUpValidators.password(_passwordController.text) == null &&
      _agreedToTerms;

  void _onInputChanged(String _) => setState(() {});

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    // go: 회원가입 화면을 없애고 홈으로 이동 → 뒤로가기로 돌아오지 않음
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '회원가입'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 넓은 화면(700 이상)에서는 Form 최대 너비를 560으로 제한합니다.
            final maxFormWidth =
                constraints.maxWidth >= 700 ? 560.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RegisterHeader(),
                        const SizedBox(height: 32),
                        MovieLogTextFormField(
                          controller: _nicknameController,
                          label: '닉네임',
                          hint: '두 글자 이상 입력',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: SignUpValidators.nickname,
                          onChanged: _onInputChanged,
                          onFieldSubmitted: (_) =>
                              _emailFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        MovieLogTextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          label: '이메일',
                          hint: 'movie@example.com',
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: SignUpValidators.email,
                          onChanged: _onInputChanged,
                          onFieldSubmitted: (_) =>
                              _passwordFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        MovieLogTextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          label: '비밀번호',
                          hint: '8자 이상 입력',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: SignUpValidators.password,
                          onChanged: _onInputChanged,
                          // 키보드 완료 버튼 → 키보드 닫기
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 16),
                        TermsAgreement(
                          agreed: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        RegisterSubmitButton(
                          // null이면 버튼이 비활성화됩니다.
                          onPressed: _canSubmit ? _submit : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MovieLog에 오신 걸 환영해요', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        Text(
          '닉네임, 이메일, 비밀번호를 입력하고 약관에 동의해주세요.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}

class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!agreed),
      child: Row(
        children: [
          Checkbox(
            value: agreed,
            onChanged: (value) => onChanged(value ?? false),
          ),
          const Expanded(
            child: Text(
              '(필수) 서비스 이용약관 및 개인정보 처리방침에 동의합니다.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterSubmitButton extends StatelessWidget {
  const RegisterSubmitButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // 활성화·비활성화 색상은 AppTheme의 elevatedButtonTheme에서 지정합니다.
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Text('회원가입'),
    );
  }
}
