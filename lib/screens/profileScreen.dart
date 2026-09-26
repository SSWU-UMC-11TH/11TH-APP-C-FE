import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/widgets/AppBar.dart';
import 'package:movielog/theme/app_theme.dart';

import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'), // 공용 AppBar 적용
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              ProfileHeader(),
              SizedBox(height: 24),
              ProfileStats(),
              SizedBox(height: 32),
              FavoriteGenres(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 프로필 사진 + 이름 + 소개 + 수정 버튼 ──────────
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('무비러버', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋\n은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}

// ── 통계 3개 (StatItem 재사용) ──────────────────
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: StatItem(value: '342', label: '본 영화'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(value: '4.2', label: '평점'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(value: '58', label: '즐겨찾기'),
        ),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F3F0),
        border: Border.all(color: AppColors.border), // 테두리
        borderRadius: BorderRadius.circular(8), // 둥근 모서리
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodySmall,),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleLarge?.copyWith(color: colors.primary)),
        ],
      ),
    );
  }
}

// ── 선호 장르 Chip ──────────────────────────────
class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // SvgPicture.asset(
            //   'assets/icons/genre.svg',
            //   width: 18,
            //   height: 18,
            //   colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            // ),
            const SizedBox(width: 6),
            Text('선호하는 장르', style: textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres
              .map(
                (genre) => Chip(
                  label: Text(genre),
                  backgroundColor: Color(0xFFE9DDFF),
                  labelStyle: TextStyle(color: colors.primary),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
