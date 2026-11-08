import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/tag_pill.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  static const List<String> _favoriteGenres = ['드라마', 'SF', '애니메이션'];

  void _showPreparing(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('준비 중인 기능입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: const Text(
          '내 프로필',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _ProfileHeader(
            nickname: '무비러버',
            bio: '매주 주말엔 영화관으로 출근하는 프로 관람객. '
                '좋은 영화를 보고 기록하는 것을 좋아합니다.',
            onEditTap: () => _showPreparing(context),
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

/// 프로필 사진, 닉네임, 소개, 프로필 수정 버튼.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nickname,
    required this.bio,
    required this.onEditTap,
  });

  final String nickname;
  final String bio;
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
          // 프로필 이미지 Asset이 있으면 backgroundImage로 바꾸면 된다.
          child: const CircleAvatar(
            backgroundColor: AppColors.lavender,
            child: Icon(Icons.person, size: 48, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nickname,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSub,
          ),
        ),
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
        color: AppColors.lavenderLight,
        borderRadius: BorderRadius.circular(12),
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