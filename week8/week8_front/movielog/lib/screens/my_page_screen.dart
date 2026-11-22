import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tag_pill.dart';

/// 마이페이지. (Figma W8-06 · W8-CH02 로딩 · W8-CH03 실패 · W8-CH04 가입일)
///
/// [8주차] GET me로 받은 내 정보(닉네임·이메일·가입일)를 표시한다.
/// AuthViewModel.member를 read가 아니라 watch로 구독하므로, 프로필 수정에 성공하면
/// 화면 이동이나 새로고침 없이 새 닉네임이 바로 보인다.
///
/// 사진·통계·장르는 기존 디자인 예시(Mock)이고, v7 GET me 응답은 이메일·닉네임·가입일뿐이다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  static const List<String> _favoriteGenres = ['드라마', 'SF', '애니메이션'];

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    // [Challenge] MainScreen이 시작한 내 정보 로딩 상태(memberStatus)를 구독한다.
    // 불러오는 동안에는 화면 전체에 인디케이터를, 실패하면 재시도 버튼을 보여준다.
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text('내 프로필', style: _titleStyle),
        ),
        body: auth.memberStatus == MemberLoadStatus.error
            ? _MemberLoadError(
                // 네트워크 실패는 로그아웃하지 않고 다시 불러올 수 있게 한다.
                onRetry: () => auth.loadMember(force: true),
              )
            : const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text('내 프로필', style: _titleStyle),
        actions: [
          // 토큰과 member를 지운다. signedOut이 되면 Router가 /login으로 보낸다.
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: auth.storageCleanupInProgress
                ? null
                : () => context.read<AuthViewModel>().logout(),
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _ProfileHeader(
            member: member,
            // 자식 화면(/my/profile/edit)으로 push → 저장하면 마이페이지로 돌아온다.
            onEditTap: () => context.push('/my/profile/edit'),
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              Expanded(child: _StatBox(label: '본 영화', value: '342')),
              SizedBox(width: 8),
              Expanded(child: _StatBox(label: '평점', value: '4.2')),
              SizedBox(width: 8),
              Expanded(child: _StatBox(label: '즐겨찾기', value: '58')),
            ],
          ),
          const SizedBox(height: 20),
          // [6주차] 자식 화면(/my/ratings)으로 push → 뒤로 가면 마이페이지로 돌아온다.
          _MenuTile(
            label: '내가 등록한 평점',
            onTap: () => context.push('/my/ratings'),
          ),
          const SizedBox(height: 28),
          const Text(
            '선호하는 장르',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in _favoriteGenres)
                TagPill(label: genre, color: AppColors.lavender),
            ],
          ),
        ],
      ),
    );
  }
}

/// [Challenge] `MemberInfo.createdAt`을 "2026.10.10 가입" 형식으로 바꾼다.
String formatJoinedDate(DateTime createdAt) {
  final local = createdAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}.$month.$day 가입';
}

/// [Challenge] 내 정보를 불러오지 못했을 때. (Figma W8-CH03)
class _MemberLoadError extends StatelessWidget {
  const _MemberLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '내 정보를 불러오지 못했어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
            const SizedBox(height: 16),
            MovieLogButton(label: '다시 시도', width: 120, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// 프로필 사진, 닉네임, 가입일, 이메일, 프로필 수정 버튼.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.member, required this.onEditTap});

  final MemberInfo member;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const CircleAvatar(
            backgroundColor: AppColors.lavender,
            backgroundImage: AssetImage(
              'assets/images/profile/profile_movielog.jpg',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          member.nickname,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        // [Challenge] 닉네임 아래 가입일
        Text(formatJoinedDate(member.createdAt), style: AppTextStyles.bodySmall),
        const SizedBox(height: 2),
        Text(member.email, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onEditTap,
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}

/// 본 영화 / 평점 / 즐겨찾기 숫자 하나를 담는 박스 (Mock 숫자).
class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSub),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 테두리가 있는 한 줄 메뉴. 오른쪽 화살표로 자식 화면이 있음을 알린다.
class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
