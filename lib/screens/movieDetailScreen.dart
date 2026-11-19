import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../data/mock_movie.dart';
import '../widgets/movie__rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

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
      SnackBar(content: Text(isFavorite ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 삭제했어요')),
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

    if (result != null) {
      setState(() => myRating = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Image.asset(
                movie.posterAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(movie.title, style: Theme.of(context).textTheme.headlineSmall),
            Text('${movie.year} · ${movie.genre}'),
            const SizedBox(height: 12),

            // 평균 평점 (읽기 전용)
            Row(
              children: [
                RatingBarIndicator(
                  rating: 4.5,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                const Text('4.5'),
              ],
            ),

            // 내가 남긴 평점
            if (myRating > 0) ...[
              const SizedBox(height: 8),
              Text('내 평점: $myRating'),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    ),
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
