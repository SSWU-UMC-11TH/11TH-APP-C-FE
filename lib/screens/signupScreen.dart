import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
  //포커스 이동
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    //입력값이 바뀔 때마다 버튼 활성화 조건 검사
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
    final isValid =
        _nicknameController.text.trim().length >= 2 &&
        _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.length >= 8 &&
        _agreedToTerms;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value);
  }

  void _onAgreeChanged(bool? value) {
    setState(() {
      _agreedToTerms = value ?? false;
    });
    _validateForm();
  }

  // void _onSubmit() {
  //   final isFormOk = _formKey.currentState?.validate() ?? false;
  //   if (isFormOk && _agreedToTerms) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('가입 처리 중입니다.')));
  //   } else if (!_agreedToTerms) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요.')));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 뒤로가기 버튼 + 타이틀을 직접 배치
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
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
                            const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
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
                                      Text(
                                        '환영합니다!',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      Text(
                                        '간단한 정보만 입력하고 시작해보세요.',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                NicknameField(controller: _nicknameController),
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

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isFormValid
                                        ? () => context.go('/home')
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      disabledBackgroundColor: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      disabledForegroundColor: Colors.white
                                          .withValues(alpha: 0.8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('가입하기'),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

// ── 닉네임 입력창 ─────────────────────────────
class NicknameField extends StatefulWidget {
  const NicknameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<NicknameField> createState() => _NicknameFieldState();
}

class _NicknameFieldState extends State<NicknameField> {
  String? _errorText;

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (value.trim().length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          onChanged: (value) {
            setState(() {
              _errorText = _validate(value);
            });
          },
          decoration: InputDecoration(
            hintText: '닉네임을 입력해주세요',
            filled: true,
            fillColor: hasError
                ? Colors.red.withValues(alpha: 0.08) // 에러일 때 연한 빨간 배경
                : Colors.white, // 평소엔 흰색
            suffixIcon: hasError
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      'assets/icons/error.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB3261E)),
            ),
          ),
          validator: _validate,
        ),
      ],
    );
  }
}

// ── 이메일 입력창 ──────────────────────────────
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

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value);
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!_isValidEmail(value.trim())) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _errorText = _validate(value);
            });
          },
          onFieldSubmitted: (_) => widget.onSubmitted(),
          decoration: InputDecoration(
            hintText: '이메일 주소를 입력해주세요',
            filled: true,
            fillColor: hasError
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.white,
            suffixIcon: hasError
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      'assets/icons/error.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: _validate,
        ),
      ],
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
  bool _obscureText = true;

  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;

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
            setState(() {
              _errorText = _validate(value);
            });
          },
          onFieldSubmitted: (_) => widget.onSubmitted(),
          decoration: InputDecoration(
            hintText: '비밀번호를 입력해주세요',
            filled: true,
            fillColor: hasError
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.white,
            suffixIcon: hasError
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      'assets/icons/error.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFCBC4D2)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: _validate,
        ),
      ],
    );
  }
}
