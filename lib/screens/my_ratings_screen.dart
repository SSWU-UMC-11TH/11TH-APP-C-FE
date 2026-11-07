import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점 (root Navigator 위에 열려 하단 탭이 보이지 않습니다)
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.pop(),
        actions: [
          // Empty·Error 화면 확인용 메뉴는 개발(debug) 모드에서만 보입니다.
          if (kDebugMode) const _DebugMemberMenu(),
        ],
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const MovieListLoading(),
            MyRatingsLoadStatus.error => MovieListError(
                message: viewModel.message,
                onRetry: () => context.read<MyRatingsViewModel>().load(),
              ),
            MyRatingsLoadStatus.empty =>
              const MovieListEmpty(message: '아직 등록한 평점이 없어요.'),
            MyRatingsLoadStatus.success => _RatingList(
                ratings: viewModel.ratings,
                memberId: viewModel.memberId,
                notice: viewModel.message,
              ),
          };
        },
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({
    required this.ratings,
    required this.memberId,
    required this.notice,
  });

  final List<RatingWithMovie> ratings;
  final int memberId;

  /// 일부 영화 정보를 못 가져왔을 때의 안내
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 로그인한 본인의 평점이 아니라 학습용 공개 데이터임을 밝힙니다.
        Text(
          '학습용 memberId $memberId의 평점 ${ratings.length}개',
          style: AppTextStyles.bodySmall,
        ),
        if (notice != null) ...[
          const SizedBox(height: 8),
          Text(
            notice!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        for (final entry in ratings) ...[
          RatingCard(entry: entry),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// 평점 카드: TMDB 포스터·제목 + 점수 + 후기 + 등록일
class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.entry});

  final RatingWithMovie entry;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final stars = rating.score.clamp(0, 5).toInt();
    final comment = rating.comment;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // movieId는 TMDB id라서 바로 영화 상세 화면으로 이동할 수 있습니다.
      onTap: () => context.push('/movies/${rating.movieId}', extra: movie),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영화 정보가 없으면(null) TmdbPosterImage가 placeholder를 보여줍니다.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: movie?.posterPath,
                width: 64,
                height: 96,
                size: 'w185',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보를 찾을 수 없어요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  if (movie == null)
                    Text(
                      'movieId ${rating.movieId}',
                      style: AppTextStyles.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${'★' * stars}${'☆' * (5 - stars)}  ${rating.score}점',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  // 후기가 없으면(null) 표시하지 않습니다.
                  if (comment != null && comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(comment, style: AppTextStyles.bodyMedium),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(rating.createdAt),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// debug 전용: 조회 memberId를 바꿔 Empty·Error 상태를 확인합니다.
class _DebugMemberMenu extends StatelessWidget {
  const _DebugMemberMenu();

  static const _memberIds = [1, 2, 3, 4, 5, 999999];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<MyRatingsViewModel>();
    return PopupMenuButton<int>(
      tooltip: '조회 memberId 바꾸기 (debug)',
      icon: const Icon(Icons.tune),
      initialValue: viewModel.memberId,
      onSelected: viewModel.changeMemberIdForDebug,
      itemBuilder: (context) => [
        for (final id in _memberIds)
          PopupMenuItem(
            value: id,
            child: Text(
              id == sampleMemberId ? 'memberId $id (기본)' : 'memberId $id',
            ),
          ),
      ],
    );
  }
}
