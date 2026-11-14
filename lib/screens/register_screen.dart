import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_text_form_field.dart';

/// 회원가입 입력값 검증 규칙. validator는 오류면 문구, 통과면 null을 반환합니다.
abstract final class SignUpValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// v6 서버 규칙: 대문자·소문자·숫자·특수문자(!@#$%^&*)를 모두 포함한 8자 이상
  static final _passwordPattern =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$');

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
    if (!_passwordPattern.hasMatch(password)) {
      return '대문자/소문자/숫자/특수문자를 모두 포함해주세요.';
    }
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

  /// 형식 검사(로컬) + 서버 중복 확인 + 약관 동의가 모두 끝나야 가입할 수 있습니다.
  bool _canSubmit(SignUpViewModel viewModel) =>
      SignUpValidators.nickname(_nicknameController.text) == null &&
      SignUpValidators.email(_emailController.text) == null &&
      SignUpValidators.password(_passwordController.text) == null &&
      _agreedToTerms &&
      viewModel.isAllAvailable &&
      !viewModel.isSubmitting;

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final viewModel = context.read<SignUpViewModel>();
    if (!isValid || !_canSubmit(viewModel)) return;

    FocusScope.of(context).unfocus();
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    // await 뒤에는 화면이 이미 사라졌을 수 있습니다.
    if (!mounted) return;

    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      // ScaffoldMessenger는 앱 최상단에 있어서 화면이 바뀌어도 Snackbar가 남습니다.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('회원가입 완료! 학습용 memberId: $memberId'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      // go: 회원가입 화면을 없애고 영화 목록으로 이동 → 뒤로가기로 돌아오지 않음
      context.go('/movies');
      return;
    }

    final message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<SignUpViewModel, bool>(
      (viewModel) => viewModel.isSubmitting,
    );

    // 제출 중에는 뒤로가기·스와이프 백으로 화면을 벗어나지 못합니다.
    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
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
                      // 중복 확인 상태가 바뀔 때 Form 영역만 다시 그립니다.
                      child: Consumer<SignUpViewModel>(
                        builder: (context, viewModel, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const RegisterHeader(),
                              const SizedBox(height: 32),
                              DuplicateCheckRow(
                                status: viewModel.nicknameCheckStatus,
                                availableMessage: '사용할 수 있는 닉네임입니다.',
                                // 형식이 맞고, 확인 가능한 상태일 때만 누를 수 있습니다.
                                onCheck: viewModel.canCheckNickname &&
                                        !viewModel.isSubmitting &&
                                        SignUpValidators.nickname(
                                              _nicknameController.text,
                                            ) ==
                                            null
                                    ? () => viewModel
                                        .checkNickname(_nicknameController.text)
                                    : null,
                                field: MovieLogTextFormField(
                                  controller: _nicknameController,
                                  label: '닉네임',
                                  hint: '두 글자 이상 입력',
                                  prefixIcon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: SignUpValidators.nickname,
                                  // 서버 결과(중복·통신 실패)를 입력창 에러로 연결
                                  errorText: viewModel.nicknameErrorText,
                                  suffixIcon: _checkMark(
                                    viewModel.nicknameCheckStatus,
                                  ),
                                  onChanged: (value) {
                                    viewModel.onNicknameChanged(value);
                                    setState(() {});
                                  },
                                  onFieldSubmitted: (_) =>
                                      _emailFocusNode.requestFocus(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DuplicateCheckRow(
                                status: viewModel.emailCheckStatus,
                                availableMessage: '사용할 수 있는 이메일입니다.',
                                onCheck: viewModel.canCheckEmail &&
                                        !viewModel.isSubmitting &&
                                        SignUpValidators.email(
                                              _emailController.text,
                                            ) ==
                                            null
                                    ? () => viewModel
                                        .checkEmail(_emailController.text)
                                    : null,
                                field: MovieLogTextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: '이메일',
                                  hint: 'movie@example.com',
                                  prefixIcon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: SignUpValidators.email,
                                  errorText: viewModel.emailErrorText,
                                  suffixIcon: _checkMark(
                                    viewModel.emailCheckStatus,
                                  ),
                                  onChanged: (value) {
                                    viewModel.onEmailChanged(value);
                                    setState(() {});
                                  },
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              MovieLogTextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                label: '비밀번호',
                                hint: '대·소문자, 숫자, 특수문자 포함 8자 이상',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                // 로컬 validator + 서버 400 문구를 함께 연결합니다.
                                validator: SignUpValidators.password,
                                errorText: viewModel.passwordErrorText,
                                onChanged: (_) {
                                  viewModel.onPasswordChanged();
                                  setState(() {});
                                },
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
                              // Form 하단 버튼: 부모 최대 너비(double.infinity)
                              MovieLogButton(
                                label: '가입하기',
                                width: double.infinity,
                                isLoading: viewModel.isSubmitting,
                                onPressed:
                                    _canSubmit(viewModel) ? _submit : null,
                              ),
                            ],
                          );
                        },
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

  /// 사용 가능으로 확인되면 입력창 안쪽에만 체크 표시를 둡니다.
  Widget? _checkMark(CheckStatus status) {
    if (status != CheckStatus.available) return null;
    return const Icon(Icons.check_circle, color: AppColors.primary);
  }
}

/// 입력창 + 중복 확인 버튼(Row의 형제, 8px 간격) + 사용 가능 안내 문구
class DuplicateCheckRow extends StatelessWidget {
  const DuplicateCheckRow({
    super.key,
    required this.field,
    required this.status,
    required this.onCheck,
    required this.availableMessage,
  });

  final Widget field;
  final CheckStatus status;

  /// null이면 버튼 비활성화
  final VoidCallback? onCheck;
  final String availableMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 8),
            // 입력창 옆 보조 버튼: width를 주지 않아 내용 기반 크기(null)
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
        // 중복·통신 실패 문구는 입력창 errorText로, 사용 가능 문구만 여기에 표시합니다.
        if (status == CheckStatus.available)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              availableMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
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
