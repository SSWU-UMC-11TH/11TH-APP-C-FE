import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_theme.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/movielog_button.dart';

/// 회원가입 화면.
///
/// [6주차] 닉네임·이메일 입력란 옆에 중복 확인 버튼을 두고,
/// 확인 결과(상태·에러 문구)는 SignUpViewModel에서 받아 그린다.
/// [7주차] 유효한 입력을 실제 v6 회원가입 POST로 전송하고,
/// 성공하면 result.memberId를 학습용 현재 회원(LearningMemberSession)에 저장한다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// [7주차] 로컬 Form 검증 → 회원가입 POST → 결과에 따라 이동 또는 Snackbar.
  Future<void> _onSubmitPressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final viewModel = context.read<SignUpViewModel>();
    // 비밀번호는 로그·SharedPreferences에 남기지 않고 요청 body로만 보낸다.
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final createdMemberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success &&
        createdMemberId != null) {
      context.read<LearningMemberSession>().setMemberId(createdMemberId);
      // 가입 결과의 memberId를 확인할 수 있게 안내한다. (root ScaffoldMessenger라 이동 후에도 보인다)
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다. (memberId: $createdMemberId)'),
          ),
        );
      // go를 쓰면 영화 목록에서 회원가입으로 뒤로 갈 수 없다.
      context.go('/movies');
      return;
    }

    final message = viewModel.snackbarMessage;
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '닉네임을 입력해 주세요.';
    if (text.length < 2 || text.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '이메일을 입력해 주세요.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return '이메일 형식이 올바르지 않습니다.';
    return null;
  }

  /// [7주차] 서버 제약과 같은 규칙으로 빠르게 안내한다. (서버 검증을 대체하지 않는다)
  /// 8자 이상 + 소문자·대문자·숫자·특수문자(!@#$%^&*) 각각 하나 이상.
  String? _validatePasswordFormat(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return '비밀번호를 입력해 주세요.';
    if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    final hasLower = RegExp(r'[a-z]').hasMatch(text);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(text);
    final hasDigit = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#$%^&*]').hasMatch(text);
    if (!hasLower || !hasUpper || !hasDigit || !hasSpecial) {
      return '소문자·대문자·숫자·특수문자(!@#\$%^&*)를 각각 하나 이상 포함해 주세요.';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if ((value ?? '').isEmpty) return '비밀번호를 한 번 더 입력해 주세요.';
    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // [Challenge] 제출 중에는 뒤로가기·스와이프 백으로 화면을 벗어날 수 없다.
    // 제출이 끝나면(성공이든 실패든) 다시 나갈 수 있다.
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        return PopScope(
          canPop: !viewModel.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              // 회원가입 화면에서는 뒤로 가기 버튼을 만들지 않는다.
              automaticallyImplyLeading: false,
              title: const Text('회원가입'),
            ),
            body: child,
          ),
        );
      },
      child: SafeArea(
        child: Form(
          key: _formKey,
          // ViewModel이 notifyListeners()를 부르면 Consumer의 builder만 다시 그린다.
          child: Consumer<SignUpViewModel>(
            builder: (context, viewModel, child) {
              final isSubmitting = viewModel.isSubmitting;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _DuplicateCheckField(
                    controller: _nicknameController,
                    labelText: '닉네임',
                    enabled: !isSubmitting,
                    validator: _validateNickname,
                    status: viewModel.nicknameCheckStatus,
                    errorText: viewModel.nicknameErrorText,
                    availableText: '사용할 수 있는 닉네임입니다.',
                    onChanged: viewModel.onNicknameChanged,
                    onCheck: viewModel.canCheckNickname
                        ? () => viewModel.checkNickname(
                              _nicknameController.text,
                            )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _DuplicateCheckField(
                    controller: _emailController,
                    labelText: '이메일',
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    status: viewModel.emailCheckStatus,
                    errorText: viewModel.emailErrorText,
                    availableText: '사용할 수 있는 이메일입니다.',
                    onChanged: viewModel.onEmailChanged,
                    onCheck: viewModel.canCheckEmail
                        ? () => viewModel.checkEmail(_emailController.text)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      border: const OutlineInputBorder(),
                      // 로컬 validator가 통과해도 서버가 거부한 값이면 계속 에러로 보인다.
                      errorText: viewModel.passwordErrorText,
                      errorMaxLines: 2,
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: _validatePasswordFormat,
                    onChanged: (_) => viewModel.onPasswordChanged(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: _validatePasswordConfirm,
                  ),
                  const SizedBox(height: 32),
                  // Form 하단 버튼: 부모(ListView)가 허용하는 최대 너비를 모두 쓴다.
                  // 제출 중에는 회색 + 인디케이터로 바뀌어 다시 누를 수 없다.
                  MovieLogButton(
                    label: '가입하기',
                    width: double.infinity,
                    isLoading: isSubmitting,
                    onPressed: viewModel.canSubmit ? _onSubmitPressed : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 입력창 + 중복 확인 버튼 + 사용 가능 안내 문구.
///
/// 닉네임과 이메일이 같은 구조를 쓰므로 묶었다. 상태는 갖지 않고
/// SignUpViewModel의 값을 그대로 전달받아 그리기만 한다.
class _DuplicateCheckField extends StatelessWidget {
  const _DuplicateCheckField({
    required this.controller,
    required this.labelText,
    required this.enabled,
    required this.validator,
    required this.status,
    required this.errorText,
    required this.availableText,
    required this.onChanged,
    required this.onCheck,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String labelText;

  /// [7주차] 제출 중에는 입력을 바꾸지 못하게 한다.
  final bool enabled;
  final FormFieldValidator<String> validator;
  final CheckStatus status;

  /// 서버 중복·통신 실패 문구. 값이 있으면 입력창이 붉은 에러 상태가 된다.
  final String? errorText;
  final String availableText;
  final ValueChanged<String> onChanged;

  /// null이면 중복 확인 버튼이 비활성화된다.
  final VoidCallback? onCheck;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == CheckStatus.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // 에러 문구가 생겨 입력창이 길어져도 버튼은 입력칸 옆에 머문다.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: labelText,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                  // 체크 표시는 입력창 안에만 두어 버튼과 겹치지 않게 한다.
                  suffixIcon: isAvailable
                      ? const Icon(Icons.check_circle, color: AppColors.violet)
                      : null,
                ),
                validator: validator,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            // 입력창 옆 보조 버튼: width를 주지 않아(null) 내용 기반 크기를 쓴다.
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: MovieLogButton(
                label: '중복 확인',
                isLoading: status == CheckStatus.checking,
                onPressed: onCheck,
              ),
            ),
          ],
        ),
        if (isAvailable)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(availableText, style: AppTextStyles.bodySmall),
          ),
      ],
    );
  }
}
