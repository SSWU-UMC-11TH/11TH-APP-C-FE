import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_theme.dart';
import '../utils/movie_format.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 영화 상세 화면.
///
/// [5주차] Path의 movieId는 TMDB 영화 id다. (배열 index가 아니다)
/// [7주차] 영화 DTO는 MovieDetailLoader가 준비해 MovieDetailViewModel에 넣어 준다.
/// 이 화면에서는 평점 "등록"만 하고, 결과는 같은 화면의 Snackbar로 안내한다.
/// 조회·수정·삭제는 마이페이지의 '내가 등록한 평점' 화면에서 한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 즐겨찾기는 이 화면 내부 상태로만 관리한다.
  bool _isFavorite = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      // URL로 바로 들어와 돌아갈 화면이 없으면 영화 목록으로 보낸다.
      context.go('/movies');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _showMessage(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
  }

  /// [7주차] 평점 Dialog → v6 POST → 결과 Snackbar.
  ///
  /// movieId는 이 화면이 구독 중인 MovieDetailViewModel이 이미 갖고 있으므로
  /// onSubmit 콜백 밖으로 따로 전달하지 않는다.
  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            final message = viewModel.submitMessage ?? '저장에 실패했습니다.';
            // 실패: 서버 message(400·404·409 구분)를 Snackbar로 알리고,
            // Dialog는 닫지 않아 입력을 그대로 유지한다.
            if (mounted) _showMessage(message);
            throw StateError(message);
          }
        },
      ),
    );

    // 저장 요청과 Snackbar 표시는 서로 다른 비동기 경계이므로 mounted를 다시 확인한다.
    if (!mounted || saved != true) return;

    _showMessage('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: const Text(
          'Cinema Archive',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 0.6,
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          _MovieInfo(movie: movie),
          const Divider(height: 1, color: AppColors.divider),
          _Synopsis(text: movie.overview),
        ],
      ),
      bottomNavigationBar: _DetailActionBar(
        isFavorite: _isFavorite,
        onFavoriteTap: _toggleFavorite,
        // memberId가 없으면 등록 버튼을 비활성화하고 회원가입으로 안내한다.
        onRateTap: viewModel.canRate ? _openRatingDialog : null,
      ),
    );
  }
}

/// 제목, 출시 연도, 평균 평점.
class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = releaseYear(movie.releaseDate);
    final rating = toFivePointRating(movie.voteAverage);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          // release_date가 null이면 출시 연도를 표시하지 않는다.
          if (year != null) ...[
            const SizedBox(height: 4),
            Text(
              year,
              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // 읽기 전용 표시. TMDB 평점(0~10)을 5점 만점으로 바꿔 그린다.
              RatingBarIndicator(
                rating: rating,
                itemCount: 5,
                itemSize: 18,
                unratedColor: AppColors.starOff,
                itemBuilder: (context, index) {
                  return const Icon(Icons.star, color: AppColors.primary);
                },
              ),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Synopsis extends StatelessWidget {
  const _Synopsis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시놉시스',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // overview가 비어 있으면 가운데에 안내 문구를 보여준다.
          if (text.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '줄거리 정보가 없어요.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSub),
                ),
              ),
            )
          else
            Text(text, style: const TextStyle(fontSize: 14, height: 1.7)),
        ],
      ),
    );
  }
}

/// 화면 아래에 고정된 즐겨찾기 / 평점 남기기 버튼.
class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onRateTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  /// null이면 평점 남기기 버튼이 비활성화된다. (학습용 회원가입 전)
  final VoidCallback? onRateTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // [7주차] 회원가입 결과의 memberId가 없으면 평점을 남길 수 없다고 안내한다.
              if (onRateTap == null) ...[
                const Text(
                  '평점을 남기려면 먼저 학습용 회원가입을 완료해 주세요.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: onFavoriteTap,
                        // 즐겨찾기 여부에 따라 아이콘이 바뀐다.
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                        ),
                        label: const Text('즐겨찾기'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: onRateTap,
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('평점 남기기'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
