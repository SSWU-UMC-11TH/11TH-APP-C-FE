import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/errors/user_facing_exception.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
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
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const MovieListLoading(),
            // 저장 성공 뒤 재조회만 실패했다면 그 사실을 따로 안내합니다.
            MyRatingsLoadStatus.error => MovieListError(
                message: viewModel.refreshWarning ?? viewModel.message,
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

/// 평점 카드: TMDB 포스터·제목 + 점수 + 후기 + 등록일 + 오른쪽 수정·삭제 버튼
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
            Column(
              children: [
                IconButton(
                  onPressed: () => onEditPressed(context, rating),
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.primary,
                  tooltip: '평점 수정',
                ),
                IconButton(
                  onPressed: () => onDeletePressed(context, rating),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: '평점 삭제',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 수정: 등록과 같은 RatingDialog를 기존 score/comment로 채워서 엽니다.
/// (comment가 null이면 TextField는 빈 칸으로 시작합니다)
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment,
      // 실패하면 updateRating이 UserFacingException을 던지고 Dialog가 문구를 보여줍니다.
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
  // 성공하면 ViewModel이 이미 목록을 다시 조회했습니다.
}

/// 삭제: 확인 Dialog에서 "삭제"를 눌러야만 DELETE를 보냅니다. (취소 → 요청 없음)
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
  // 반환값 true는 실제로 삭제까지 마쳤을 때만입니다.
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          '평점을 삭제할까요?',
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '삭제한 평점은 복구할 수 없습니다.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed:
                _isDeleting ? null : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _isDeleting ? null : _onConfirm,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on UserFacingException catch (error) {
      // 403(남의 평점)·404(이미 없는 평점)를 서버 문구로 구별해 보여줍니다.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }
}
