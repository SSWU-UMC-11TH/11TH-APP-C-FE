import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  /// Path Parameter로 받은 TMDB 영화 id
  final int? movieId;

  /// 목록에서 extra로 넘겨준 DTO. URL로 바로 들어오면 null입니다.
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Future<TmdbMovieDto>? _movieFuture;

  bool _isFavorite = false;
  double? _myRating;

  @override
  void initState() {
    super.initState();
    _movieFuture = _loadMovie();
  }

  /// extra가 있으면 그대로 쓰고, 없으면 id로 TMDB에서 다시 조회합니다.
  Future<TmdbMovieDto>? _loadMovie() {
    final initial = widget.initialMovie;
    if (initial != null && initial.id == widget.movieId) {
      return Future.value(initial);
    }
    final id = widget.movieId;
    if (id == null) return null;
    return context.read<TmdbMovieService>().fetchMovieDetail(id);
  }

  void _retry() {
    setState(() {
      _movieFuture = _loadMovie();
    });
  }

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

  Future<void> _openRatingDialog(TmdbMovieDto movie) async {
    final result = await showDialog<double>(
      context: context,
      // TMDB id를 그대로 전달 → 이후 평점 API의 movieId로 사용
      builder: (context) => RatingDialog(
        movieId: movie.id,
        initialRating: _myRating ?? 0,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _myRating = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movieFuture = _movieFuture;
    if (movieFuture == null) {
      return Scaffold(
        appBar: CommonAppBar(title: '영화 상세', onBack: () => context.pop()),
        body: const Center(child: Text('영화를 찾을 수 없어요.')),
      );
    }

    return FutureBuilder<TmdbMovieDto>(
      future: movieFuture,
      builder: (context, snapshot) {
        final movie = snapshot.data;

        return Scaffold(
          appBar: CommonAppBar(
            title: movie?.title ?? '영화 상세',
            // push로 쌓인 화면이므로 pop으로 이전 화면(홈/목록)으로 돌아갑니다.
            onBack: () => context.pop(),
            actions: [
              if (movie != null)
                IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  color: AppColors.primary,
                  tooltip: '즐겨찾기',
                ),
            ],
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<TmdbMovieDto> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const MovieListLoading();
    }
    if (snapshot.hasError) {
      return MovieListError(
        message: '영화 정보를 불러오지 못했어요.',
        onRetry: _retry,
      );
    }

    final movie = snapshot.data;
    if (movie == null) {
      return const Center(child: Text('영화를 찾을 수 없어요.'));
    }

    return _MovieDetailBody(
      movie: movie,
      myRating: _myRating,
      onRate: () => _openRatingDialog(movie),
    );
  }
}

class _MovieDetailBody extends StatelessWidget {
  const _MovieDetailBody({
    required this.movie,
    required this.myRating,
    required this.onRate,
  });

  final TmdbMovieDto movie;
  final double? myRating;
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
        if (myRating != null) ...[
          Text('내 평점: $myRating점', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: onRate,
          child: Text(myRating == null ? '평점 남기기' : '평점 수정하기'),
        ),
      ],
    );
  }
}
