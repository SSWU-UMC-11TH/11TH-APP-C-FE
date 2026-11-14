import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';
import 'package:provider/provider.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final TmdbMovieDto? movie;

  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  TmdbMovieDto? _movie;
  bool _loading = false;
  bool _failed = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    if (_movie == null) _loadMovie(); // 직접 접근·새로고침 대비
  }

  Future<void> _loadMovie() async {
    final service = context.read<TmdbMovieService>();
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final movie = await service.findMovieById(widget.movieId);
      if (!mounted) return;
      setState(() {
        _movie = movie;
        _loading = false;
        _failed = movie == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 삭제했어요'),
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    final vm = context.read<MovieDetailViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것 방지
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await vm.createRating(score: score, comment: comment);
          if (vm.submitStatus != SubmitStatus.success) {
            // 실패하면 Dialog가 열린 채 입력을 유지하고 서버 message를 보여줌
            throw StateError(vm.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );

    if (saved != true) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('평점을 등록했어요. 마이페이지에서 확인할 수 있어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const LoadingView());
    }

    final movie = _movie;
    if (movie == null || _failed) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: '영화 정보를 불러오지 못했어요.\n(영화 ID: ${widget.movieId})',
          onRetry: _loadMovie,
        ),
      );
    }

    final canRate = context.read<MovieDetailViewModel>().memberId != null;

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: 360,
              ),
            ),
            const SizedBox(height: 16),
            Text(movie.title,
                style: Theme.of(context).textTheme.headlineSmall),
            if (movie.releaseYear != null) Text(movie.releaseYear!),
            const SizedBox(height: 12),
            Row(
              children: [
                RatingBarIndicator(
                  rating: movie.voteAverage / 2,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                Text(movie.voteAverage.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),
            if (movie.overview.isEmpty)
              const Center(child: Text('줄거리 정보가 없어요.'))
            else
              Text(movie.overview),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_border),
                    label: const Text('즐겨찾기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    // 가입 결과의 memberId가 없으면 비활성
                    onPressed: canRate ? _showRatingDialog : null,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('평점 남기기'),
                  ),
                ),
              ],
            ),
            if (!canRate) ...[
              const SizedBox(height: 8),
              Text('회원가입을 완료하면 평점을 남길 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}