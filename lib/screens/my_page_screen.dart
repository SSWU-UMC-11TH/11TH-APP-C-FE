import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';

/// 통계 한 칸에 들어갈 데이터.
class ProfileStat {
  const ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

const _profileStats = [
  ProfileStat(label: '본 영화', value: '342'),
  ProfileStat(label: '평점', value: '4.2'),
  ProfileStat(label: '즐겨찾기', value: '58'),
];

const _favoriteGenres = ['드라마', 'SF', '애니메이션'];

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: '내 프로필'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(
              imageAsset: 'assets/images/profile/profile_movielog.jpg',
            ),
            SizedBox(height: 32),
            ProfileStats(stats: _profileStats),
            SizedBox(height: 32),
            FavoriteGenres(genres: _favoriteGenres),
            SizedBox(height: 32),
            EditProfileButton(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.imageAsset});

  /// 프로필 이미지가 없으면 null을 넘겨 기본 아이콘을 표시합니다.
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
          ),
          child: ClipOval(
            child: imageAsset == null
                ? const _DefaultProfileIcon()
                : Image.asset(
                    imageAsset!,
                    width: 144,
                    height: 144,
                    fit: BoxFit.cover,
                    // 파일을 못 읽으면 기본 아이콘으로 대체합니다.
                    errorBuilder: (context, error, stackTrace) =>
                        const _DefaultProfileIcon(),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('무비러버', style: AppTextStyles.titleLarge),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/movie.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
              semanticsLabel: '영화 아이콘',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}

class _DefaultProfileIcon extends StatelessWidget {
  const _DefaultProfileIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 144,
      color: AppColors.card,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 72, color: AppColors.gray),
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, required this.stats});

  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: StatItem(label: stats[i].label, value: stats[i].value),
          ),
        ],
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.statValue),
        ],
      ),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key, required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('선호하는 장르', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres
              .map(
                (genre) => Chip(
                  label: Text(genre),
                  backgroundColor: AppColors.primaryContainer,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 주요 동작이라 배경이 있는 ElevatedButton을 사용합니다. (아직 기능 없음)
    return ElevatedButton(
      onPressed: () {},
      child: const Text('프로필 수정'),
    );
  }
}
