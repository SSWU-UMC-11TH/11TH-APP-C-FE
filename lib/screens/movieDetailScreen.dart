import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final TmdbMovieDto? movie;

  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  double myRating = 0;

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
    double tempRating = myRating;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('평점 남기기'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => MovieRatingInput(
              rating: tempRating,
              onChanged: (value) => setDialogState(() => tempRating = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, tempRating),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      // TODO(5주차 유저별 평점 조회 API): widget.movieId와 함께 평점을 전송
      setState(() => myRating = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            '영화 정보를 불러오지 못했어요.\n(영화 ID: ${widget.movieId})',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
                  rating: movie.voteAverage / 2, // TMDB 10점 만점 → 5점 만점
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                Text(movie.voteAverage.toStringAsFixed(1)),
              ],
            ),
            if (myRating > 0) ...[
              const SizedBox(height: 8),
              Text('내 평점: $myRating'),
            ],
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
                    onPressed: _showRatingDialog,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('평점 남기기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}