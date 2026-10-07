import 'package:flutter/material.dart';
import 'package:movielog/widgets/profile_header.dart';
import 'package:movielog/widgets/stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const favoriteGenres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: ProfileHeader(
                name: '무비러버',
                bio: '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                StatCard(label: '본 영화', value: '342'),
                StatCard(label: '평점', value: '4.2'),
                StatCard(label: '즐겨찾기', value: '58'),
              ],
            ),
            const SizedBox(height: 24),
            Text('선호하는 장르',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: favoriteGenres
                  .map((g) => Chip(label: Text(g)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}