import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const double _averageRating = 4.5;

  bool _isFavorite = false;
  double? _myRating;

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
    final result = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating ?? 0),
    );

    if (result == null || !mounted) return;
    setState(() {
      _myRating = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Path Parameter로 받은 ID로 Mock Data에서 영화를 다시 찾습니다.
    final movie = findMovieById(widget.movieId);

    if (movie == null) {
      return Scaffold(
        appBar: CommonAppBar(title: '영화 상세', onBack: () => context.pop()),
        body: const Center(child: Text('영화를 찾을 수 없어요.')),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CommonAppBar(
        title: movie.title,
        // push로 쌓인 화면이므로 pop으로 이전 화면(홈/목록)으로 돌아갑니다.
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                movie.posterAsset,
                width: 220,
                height: 330,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(movie.title, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${movie.genre} · ${movie.year}', style: textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              RatingBarIndicator(
                rating: _averageRating,
                itemCount: 5,
                itemSize: 24,
                itemBuilder: (context, index) {
                  return const Icon(Icons.star, color: Colors.amber);
                },
              ),
              const SizedBox(width: 8),
              Text('$_averageRating', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text(movie.description, style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (_myRating != null) ...[
            Text('내 평점: $_myRating점', style: textTheme.titleMedium),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _openRatingDialog,
            child: Text(_myRating == null ? '평점 남기기' : '평점 수정하기'),
          ),
        ],
      ),
    );
  }
}
