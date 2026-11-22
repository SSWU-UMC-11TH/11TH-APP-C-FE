import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_input.dart';

/// [8주차] 프로필 수정 화면. (Figma W8-07 · W8-08 저장 중 · W8-09 중복 · W8-CH05 변경 확인)
///
/// email은 읽기 전용, nickname만 편집할 수 있다.
/// - 성공: AuthViewModel.member 교체 → Snackbar → 마이페이지로 복귀
/// - 입력/중복 오류: 화면에 남아 필드 아래 오류 표시 (입력값 유지)
/// - 401 세션 만료: 세션 정리 → Router가 /login으로 이동
/// - 네트워크 오류: Snackbar 안내, 로그아웃하지 않고 재시도 가능
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  /// 화면에 들어올 때의 닉네임. 변경 내용이 있는지 비교하는 기준이다.
  late final String _initialNickname;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _initialNickname = member?.nickname ?? '';
    _controller = TextEditingController(text: _initialNickname);
    // [Challenge] 입력이 바뀌면 "변경 내용 있음" 여부를 다시 계산한다.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  bool get _hasChanges => _controller.text.trim() != _initialNickname;

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      router.pop(); // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있다.
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
    // 세션 만료(401)면 save()가 false를 반환하므로 pop()을 호출하지 않는다.
  }

  /// [Challenge] 변경 내용이 있을 때 뒤로가기를 누르면 확인 Dialog를 띄운다.
  ///
  /// '나가기'를 누르면 마이페이지로 돌아가고, '계속 수정'이면 이 화면에 머문다.
  Future<void> _confirmDiscard() async {
    final router = GoRouter.of(context);

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DiscardChangesDialog(
        onStay: () => Navigator.pop(dialogContext, false),
        onLeave: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (leave != true || !mounted) return;
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>((a) => a.member?.email);

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.status == EditProfileStatus.saving;

        return PopScope(
          // 저장 중에는 나갈 수 없다. 변경 내용이 있으면 먼저 확인 Dialog를 거친다.
          canPop: !saving && !_hasChanges,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || saving) return;
            _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              scrolledUnderElevation: 0,
              leading: const BackButton(color: AppColors.primary),
              title: const Text(
                '프로필 수정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const FieldLabel('이메일 (변경할 수 없습니다)'),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // email은 읽기 전용이다.
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSub,
                      ),
                      decoration: movieLogInputDecoration(readOnly: true),
                    ),
                    const SizedBox(height: 24),
                    const FieldLabel('닉네임'),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 14),
                      decoration: movieLogInputDecoration(
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [Challenge] 저장하지 않은 변경 내용을 버릴지 묻는 Dialog. (Figma W8-CH05)
class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog({required this.onStay, required this.onLeave});

  final VoidCallback onStay;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '변경 내용을 버릴까요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              '저장하지 않은 내용은 사라집니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: MovieLogButton(
                    label: '계속 수정',
                    width: double.infinity,
                    isSecondary: true,
                    radius: 8,
                    onPressed: onStay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MovieLogButton(
                    label: '나가기',
                    width: double.infinity,
                    radius: 8,
                    onPressed: onLeave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
