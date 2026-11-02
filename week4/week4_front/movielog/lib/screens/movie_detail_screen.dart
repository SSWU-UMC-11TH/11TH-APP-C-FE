import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tag_pill.dart';

/// 영화 상세 화면.
/// Movie 객체를 통째로 받지 않고, Path Parameter의 ID로 Mock Data를 다시 찾는다.
/// (extra에만 의존하면 URL 직접 접근·앱 재시작 때 값이 없을 수 있다.)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  /// `/movies/:movieId`의 movieId. URL에서 온 값이라 문자열이다.
  final String? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 즐겨찾기와 내 평점은 이 화면 내부 상태로만 관리한다. (API 연결은 8주차)
  bool _isFavorite = false;
  double _myRating = 0;

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

  Future<void> _openRatingDialog() async {
    // Navigator.pop의 두 번째 인자로 넘긴 값이 여기로 돌아온다.
    final result = await RatingDialog.show(context, initialRating: _myRating);

    // 확인 없이 닫았거나, Dialog가 떠 있는 동안 화면이 사라진 경우.
    if (result == null || !mounted) return;

    setState(() {
      _myRating = result;
    });
    _showMessage('평점 ${result.toStringAsFixed(1)}점을 남겼습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId ?? ''));

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
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : ListView(
              children: [
                AspectRatio(
                  aspectRatio: 0.6,
                  child: MoviePoster(movie: movie, borderRadius: 0),
                ),
                _MovieInfo(movie: movie),
                const Divider(height: 1, color: AppColors.divider),
                _Synopsis(text: movie.synopsis),
              ],
            ),
      bottomNavigationBar: movie == null
          ? null
          : _DetailActionBar(
              isFavorite: _isFavorite,
              onFavoriteTap: _toggleFavorite,
              onRateTap: _openRatingDialog,
            ),
    );
  }
}

/// 제목, 연도·장르·상영 시간, 평균 평점, 태그.
class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.movie});

  final Movie movie;

  /// 1245 → "1,245"
  String _formatCount(int count) {
    return count.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+$)'),
          (match) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${movie.year} • ${movie.genre} • ${movie.runtime}분',
            style: const TextStyle(fontSize: 13, color: AppColors.textSub),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 읽기 전용 표시. 4.3 같은 소수점 값도 그대로 그려 준다.
              RatingBarIndicator(
                rating: movie.rating,
                itemCount: 5,
                itemSize: 18,
                unratedColor: AppColors.starOff,
                itemBuilder: (context, index) {
                  return const Icon(Icons.star, color: AppColors.primary);
                },
              ),
              const SizedBox(width: 8),
              Text(
                movie.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_formatCount(movie.ratingCount)})',
                style: const TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in movie.tags) TagPill(label: tag),
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
  final VoidCallback onRateTap;

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
          child: Row(
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
        ),
      ),
    );
  }
}