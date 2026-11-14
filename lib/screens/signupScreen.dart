import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

bool _isValidEmail(String value) {
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return regex.hasMatch(value);
}

bool _isValidNickname(String value) =>
    value.trim().length >= 2 && value.trim().length <= 12;

/// 8자 이상, 소문자·대문자·숫자·!@#$%^&* 중 특수문자를 각각 하나 이상
String? validatePasswordFormat(String? value) {
  if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
  if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
  final ok = RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[!@#$%^&*]').hasMatch(value);
  if (!ok) return '대문자·소문자·숫자·특수문자(!@#\$%^&*)를 모두 포함해야 합니다.';
  return null;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _isValidNickname(_nicknameController.text) &&
        _isValidEmail(_emailController.text.trim()) &&
        validatePasswordFormat(_passwordController.text) == null &&
        _agreedToTerms;

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  void _onAgreeChanged(bool? value) {
    setState(() => _agreedToTerms = value ?? false);
    _validateForm();
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = context.read<SignUpViewModel>();
    final session = context.read<LearningMemberSession>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await vm.submit(CreateMemberRequest(
      email: _emailController.text,
      password: _passwordController.text,
      nickname: _nicknameController.text,
    ));
    if (!mounted) return;

    if (vm.submitStatus == SubmitStatus.success && vm.createdMemberId != null) {
      session.setMemberId(vm.createdMemberId!); // 이후 평점 요청에 사용
      router.go('/movies');
      return;
    }

    final message = vm.snackbarMessage;
    if (message != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isSubmitting = vm.submitStatus == SubmitStatus.submitting;
    final canSubmit = _isFormValid && vm.checksPassed && !isSubmitting;

    return PopScope(
      canPop: !isSubmitting, // 제출 중에는 화면을 벗어나지 못함
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '회원가입',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text('환영합니다!',
                                            style: AppTextStyles.bodyMedium),
                                        Text('간단한 정보만 입력하고 시작해보세요.',
                                            style: AppTextStyles.bodyMedium),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  NicknameField(
                                      controller: _nicknameController),
                                  const SizedBox(height: 20),
                                  EmailField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    onSubmitted: () {
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocusNode);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  PasswordField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    onSubmitted: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        activeColor: AppColors.primary,
                                        onChanged: _onAgreeChanged,
                                      ),
                                      const Text('필수 약관에 동의합니다'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  MovieLogButton(
                                    label: '가입하기',
                                    width: double.infinity,
                                    isLoading: isSubmitting,
                                    onPressed: canSubmit ? _onSubmit : null,
                                  ),
                                  if (_isFormValid && !vm.checksPassed) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '닉네임과 이메일 중복 확인을 완료해 주세요.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('이미 계정이 있나요? '),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            '로그인',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}

// 공통 입력창 스타일
InputDecoration _decoration({
  required String hint,
  required bool hasError,
  String? serverError,
  String? helperText,
  bool available = false,
  Color errorColor = Colors.red,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    errorText: serverError,
    helperText: helperText,
    helperStyle: const TextStyle(color: Colors.green),
    filled: true,
    fillColor: hasError ? Colors.red.withValues(alpha: 0.08) : Colors.white,
    suffixIcon: hasError
        ? Padding(
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset(
              'assets/icons/error.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
            ),
          )
        : available
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: border(const Color(0xFFCBC4D2)),
    focusedBorder: border(const Color(0xFFCBC4D2)),
    errorBorder: border(errorColor),
    focusedErrorBorder: border(errorColor),
  );
}

// ── 닉네임 입력창 (중복 확인 포함) ─────────────────────
class NicknameField extends StatefulWidget {
  const NicknameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<NicknameField> createState() => _NicknameFieldState();
}

class _NicknameFieldState extends State<NicknameField> {
  String? _errorText;

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return '닉네임을 입력해주세요.';
    if (value.trim().length < 2) return '닉네임은 2자 이상이어야 합니다.';
    if (value.trim().length > 12) return '닉네임은 12자 이하여야 합니다.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, vm, child) {
        final serverError = vm.nicknameErrorText;
        final available = vm.nicknameCheckStatus == CheckStatus.available;
        final hasError = _errorText != null || serverError != null;
        final canCheck =
            vm.canCheckNickname && _isValidNickname(widget.controller.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    onChanged: (value) {
                      context.read<SignUpViewModel>().onNicknameChanged(value);
                      setState(() => _errorText = _validate(value));
                    },
                    decoration: _decoration(
                      hint: '닉네임을 입력해주세요',
                      hasError: hasError,
                      serverError: serverError,
                      helperText: available ? '사용할 수 있는 닉네임입니다.' : null,
                      available: available,
                      errorColor: const Color(0xFFB3261E),
                    ),
                    validator: _validate,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: MovieLogButton(
                    label: '중복 확인',
                    isLoading: vm.nicknameCheckStatus == CheckStatus.checking,
                    onPressed: canCheck
                        ? () => context
                            .read<SignUpViewModel>()
                            .checkNickname(widget.controller.text)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── 이메일 입력창 (중복 확인 포함) ──────────────────────
class EmailField extends StatefulWidget {
  const EmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  String? _errorText;

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return '이메일을 입력해주세요.';
    if (!_isValidEmail(value.trim())) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, vm, child) {
        final serverError = vm.emailErrorText;
        final available = vm.emailCheckStatus == CheckStatus.available;
        final hasError = _errorText != null || serverError != null;
        final canCheck =
            vm.canCheckEmail && _isValidEmail(widget.controller.text.trim());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      context.read<SignUpViewModel>().onEmailChanged(value);
                      setState(() => _errorText = _validate(value));
                    },
                    onFieldSubmitted: (_) => widget.onSubmitted(),
                    decoration: _decoration(
                      hint: '이메일 주소를 입력해주세요',
                      hasError: hasError,
                      serverError: serverError,
                      helperText: available ? '사용할 수 있는 이메일입니다.' : null,
                      available: available,
                    ),
                    validator: _validate,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: MovieLogButton(
                    label: '중복 확인',
                    isLoading: vm.emailCheckStatus == CheckStatus.checking,
                    onPressed: canCheck
                        ? () => context
                            .read<SignUpViewModel>()
                            .checkEmail(widget.controller.text)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── 비밀번호 입력창 ─────────────────────────────
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  String? _errorText;
  final bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, vm, child) {
        // 로컬 validator가 통과해도 서버가 거부하면 계속 에러로 표시
        final serverError = vm.passwordErrorText;
        final hasError = _errorText != null || serverError != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                context.read<SignUpViewModel>().onPasswordChanged();
                setState(() => _errorText = validatePasswordFormat(value));
              },
              onFieldSubmitted: (_) => widget.onSubmitted(),
              decoration: _decoration(
                hint: '비밀번호를 입력해주세요',
                hasError: hasError,
                serverError: serverError,
              ),
              validator: validatePasswordFormat,
            ),
          ],
        );
      },
    );
  }
}