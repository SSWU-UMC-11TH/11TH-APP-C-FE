import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/storage/saved_email_storage.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_input.dart';

/// [8주차] 로그인 화면. (Figma W8-03 기본 · W8-04 요청 중 · W8-05 실패 · W8-CH01 이메일 저장)
///
/// 버튼은 AuthViewModel.login()만 호출하고 직접 `context.go('/home')`으로 이동하지 않는다.
/// 상태가 signedIn으로 바뀌면 Router가 홈으로 보내고, 실패하면 signedOut과 message가 남는다.
///
/// 세션 만료로 이 화면에 왔을 때는 Snackbar로 이유를 한 번만 안내한다.
/// (직접 로그아웃하거나 로그인에 실패했을 때는 안내하지 않는다)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;
  late final SavedEmailStorage _savedEmail;

  /// [Challenge] "이메일 저장" 체크 여부
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    // initState에서는 read로 꺼내기만 하고, 상태 변경은 addListener로 받는다.
    _auth = context.read<AuthViewModel>();
    _savedEmail = context.read<SavedEmailStorage>();
    // 로그인 화면이 열려 있는 중에 만료 상태가 되는 경우
    _auth.addListener(_showSessionExpired);
    // 이미 만료된 상태로 화면이 처음 열리는 경우
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _loadSavedEmail();
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    // Snackbar를 띄우기 전에 먼저 꺼서 같은 안내가 반복되지 않게 한다.
    _auth.consumeSessionExpired();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
      );
  }

  /// [Challenge] 저장해 둔 이메일이 있으면 입력칸에 채우고 체크박스를 켠다.
  Future<void> _loadSavedEmail() async {
    try {
      final saved = await _savedEmail.read();
      if (!mounted || saved == null || saved.isEmpty) return;
      if (_email.text.isNotEmpty) return; // 이미 입력을 시작했으면 덮어쓰지 않는다.
      setState(() {
        _email.text = saved;
        _rememberEmail = true;
      });
    } catch (_) {
      // 저장된 이메일을 읽지 못해도 로그인은 그대로 할 수 있다.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final remember = _rememberEmail;

    // 비밀번호는 요청으로만 보내고 저장하거나 로그로 남기지 않는다.
    await _auth.login(email, _password.text);

    // [Challenge] 로그인에 성공했을 때만 이메일 저장 여부를 반영한다.
    // 성공하면 Router가 이 화면을 닫으므로 context를 쓰지 않는다.
    if (_auth.status != AuthStatus.signedIn) return;
    try {
      if (remember) {
        await _savedEmail.save(email);
      } else {
        await _savedEmail.clear();
      }
    } catch (_) {
      // 이메일 저장 실패는 로그인 결과에 영향을 주지 않는다.
    }
  }

  @override
  void dispose() {
    // 화면이 사라질 때 리스너를 제거한다.
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    // 로그인 통신 중과 이전 세션 정리 중에는 입력과 버튼을 막는다.
    final enabled = !loading && !auth.storageCleanupInProgress;
    final message = auth.message;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  width: 84,
                  height: 84,
                ),
                const SizedBox(height: 24),
                const Text(
                  'MovieLog에 로그인',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                const FieldLabel('이메일'),
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  style: const TextStyle(fontSize: 14),
                  decoration: movieLogInputDecoration(
                    hintText: 'movie@example.com',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? '이메일을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 20),
                const FieldLabel('비밀번호'),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 14),
                  // 로그인에 실패하면 입력칸을 붉은 테두리로 바꾼다.
                  decoration: movieLogInputDecoration(
                    hasError: message != null,
                  ),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                  onFieldSubmitted: enabled ? (_) => _submit() : null,
                ),
                // email/password 오류(AUTH401_1), 요청 실패, 저장 실패는 서로 다른 문구다.
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // [Challenge] 이메일만 shared_preferences에 저장한다.
                _RememberEmailCheckbox(
                  value: _rememberEmail,
                  onChanged: enabled
                      ? (value) => setState(() => _rememberEmail = value)
                      : null,
                ),
                const SizedBox(height: 32),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading,
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 없나요?', style: AppTextStyles.bodySmall),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.violet,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed:
                          enabled ? () => context.push('/register') : null,
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [Challenge] "이메일 저장" 체크박스. 글자를 눌러도 체크가 바뀐다. (Figma W8-CH01)
class _RememberEmailCheckbox extends StatelessWidget {
  const _RememberEmailCheckbox({required this.value, required this.onChanged});

  final bool value;

  /// null이면 누를 수 없다. (로그인 통신 중)
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.violet,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: onChanged == null
                    ? null
                    : (checked) => onChanged(checked ?? false),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '이메일 저장',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
