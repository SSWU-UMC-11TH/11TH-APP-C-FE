import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/profile_header.dart';
import 'package:movielog/widgets/stat_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const favoriteGenres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>(); // watch여야 닉네임 변경이 바로 반영
    final member = auth.member;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            // 토큰과 member를 지우면 Router가 /login으로 보냄
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: member == null
          ? (auth.memberStatus == MemberLoadStatus.error
              ? ErrorView(
                  message: '내 정보를 불러오지 못했어요.',
                  onRetry: () =>
                      context.read<AuthViewModel>().loadMember(force: true),
                )
              : const LoadingView())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ProfileHeader(
                      name: member.nickname,
                      email: member.email,
                      onEdit: () => context.push('/my/profile/edit'),
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => context.push('/my/ratings'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFD9CCEB), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('내가 등록한 평점',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('선호하는 장르',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        favoriteGenres.map((g) => Chip(label: Text(g))).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}