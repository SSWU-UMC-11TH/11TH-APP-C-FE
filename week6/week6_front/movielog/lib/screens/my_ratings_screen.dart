import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

/// [6주차] 마이페이지 → 내가 등록한 평점 (View).
///
/// 화면 이름은 '내가 등록한 평점'이지만, 로그인 기능이 없어
/// 학습용 memberId 1의 공개 평점을 조회한다. 수정·삭제 버튼은 두지 않는다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 보이지 않는다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.primary),
        title: const Text(
          '내가 등록한 평점',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      // bottomNavigationBar는 전달하지 않는다.
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading =>
              const _RatingsLoading(),
            MyRatingsLoadStatus.empty => const _RatingsEmpty(),
            MyRatingsLoadStatus.error => _RatingsError(
                message: viewModel.message,
                onRetry: viewModel.load,
              ),
            MyRatingsLoadStatus.success => _RatingsList(
                ratings: viewModel.ratings,
                notice: viewModel.message,
              ),
          };
        },
      ),
    );
  }
}

/// [Loading]
class _RatingsLoading extends StatelessWidget {
  const _RatingsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

/// [Empty] 빈 배열 응답은 실패가 아니므로 안내 문구만 보여준다.
class _RatingsEmpty extends StatelessWidget {
  const _RatingsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 48, color: AppColors.textSub),
            SizedBox(height: 12),
            Text(
              '아직 등록한 평점이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              '영화를 보고 첫 평점을 남겨 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

/// [Error] 400·404·그 밖의 실패를 ViewModel이 구분한 문구 그대로 보여준다.
class _RatingsError extends StatelessWidget {
  const _RatingsError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '평점을 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            // 고정 값 너비: 문구 길이와 관계없이 항상 같은 크기로 그린다.
            MovieLogButton(
              label: '다시 시도',
              width: 120,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// [Success]
class _RatingsList extends StatelessWidget {
  const _RatingsList({required this.ratings, this.notice});

  final List<RatingWithMovie> ratings;

  /// 일부 영화 정보를 가져오지 못했을 때의 안내. 없으면 null.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '학습용 memberId $sampleMemberId의 평점 ${ratings.length}개',
          style: AppTextStyles.bodySmall,
        ),
        if (notice != null) ...[
          const SizedBox(height: 4),
          Text(notice, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 8),
        for (var i = 0; i < ratings.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          _RatingTile(entry: ratings[i]),
        ],
      ],
    );
  }
}

/// 평점 하나: 포스터 · 제목 · 별점 · 후기 · 등록일.
class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.entry});

  final RatingWithMovie entry;

  /// 2026-09-06T12:14:03.000Z → 2026.09.06 (기기 시간대 기준)
  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // movie가 null이면 posterPath도 null → TmdbPosterImage가 placeholder를 그린다.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 72,
              height: 108,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 정보를 찾을 수 없어요',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: movie == null ? AppColors.textSub : null,
                  ),
                ),
                // 영화 정보가 없어도 어떤 영화의 평점인지 알 수 있게 movieId는 그대로 보여준다.
                if (movie == null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'movieId ${rating.movieId}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: rating.score.toDouble(),
                      itemCount: 5,
                      itemSize: 16,
                      unratedColor: AppColors.starOff,
                      itemBuilder: (context, index) {
                        return const Icon(
                          Icons.star,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${rating.score}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                // comment가 null이면 후기 줄을 그리지 않는다.
                if (comment != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDate(rating.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
