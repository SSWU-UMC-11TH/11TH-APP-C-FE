import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/errors/user_facing_exception.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면. 영화 DTO와 평점 등록 상태는 MovieDetailViewModel에서 읽습니다.
/// (영화 조회는 MovieDetailLoader가 끝낸 뒤 이 화면을 그립니다)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 즐겨찾기는 아직 서버 연동 전이라 화면 안에서만 관리합니다.
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        // movieId는 ViewModel이 이미 갖고 있으므로 따로 넘기지 않습니다.
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            // 서버 message(400/404/409)를 Dialog에 그대로 보여주고 입력을 유지합니다.
            throw UserFacingException(
              viewModel.submitMessage ?? '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
            );
          }
        },
      ),
    );

    // 저장 요청과 Snackbar는 다른 비동기 경계이므로 mounted를 다시 확인합니다.
    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;

    return Scaffold(
      appBar: CommonAppBar(
        title: movie.title,
        // push로 쌓인 화면이므로 pop으로 이전 화면(홈/목록/내 평점)으로 돌아갑니다.
        onBack: () => context.pop(),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: AppColors.primary,
            tooltip: '즐겨찾기',
          ),
        ],
      ),
      body: _MovieDetailBody(
        movie: movie,
        canRate: viewModel.canRate,
        isSubmitting: viewModel.submitStatus == SubmitStatus.submitting,
        onRate: _openRatingDialog,
      ),
    );
  }
}

class _MovieDetailBody extends StatelessWidget {
  const _MovieDetailBody({
    required this.movie,
    required this.canRate,
    required this.isSubmitting,
    required this.onRate,
  });

  final TmdbMovieDto movie;

  /// 학습용 회원가입 결과(memberId)가 있어야 평점을 등록할 수 있습니다.
  final bool canRate;
  final bool isSubmitting;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final year = releaseYearOf(movie.releaseDate);
    // TMDB 평점은 10점 만점 → 별 5개 기준으로 바꿉니다.
    final averageRating = movie.voteAverage / 2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              width: 220,
              height: 330,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(movie.title, style: AppTextStyles.titleLarge),
        // 출시일이 없으면 연도를 표시하지 않습니다.
        if (year != null) ...[
          const SizedBox(height: 4),
          Text(year, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            RatingBarIndicator(
              rating: averageRating,
              itemCount: 5,
              itemSize: 24,
              itemBuilder: (context, index) {
                return const Icon(Icons.star, color: Colors.amber);
              },
            ),
            const SizedBox(width: 8),
            Text(
              averageRating.toStringAsFixed(1),
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (movie.overview.trim().isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('줄거리 정보가 없어요.', style: AppTextStyles.bodySmall),
            ),
          )
        else
          Text(movie.overview, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        MovieLogButton(
          label: '평점 남기기',
          width: double.infinity,
          isLoading: isSubmitting,
          onPressed: canRate ? onRate : null,
        ),
        if (!canRate) ...[
          const SizedBox(height: 8),
          Text(
            '평점을 남기려면 학습용 회원가입이 필요합니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray),
          ),
        ],
      ],
    );
  }
}
