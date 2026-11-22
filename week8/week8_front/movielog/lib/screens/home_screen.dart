import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_theme.dart';
import '../utils/movie_format.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/section_header.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 전체가 홈 ViewModel의 상태를 따르므로 build 안에서 watch한다.
    final viewModel = context.watch<MovieHomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        // 홈에서는 뒤로 가기 버튼을 만들지 않는다.
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: const Text(
          'MovieLog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.primary),
          ),
        ],
      ),
      body: switch (viewModel.status) {
        MovieHomeLoadStatus.idle ||
        MovieHomeLoadStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        MovieHomeLoadStatus.error => MovieListError(
            message: viewModel.message,
            // 버튼 콜백에서는 한 번만 호출하므로 read를 쓴다.
            onRetry: () => context.read<MovieHomeViewModel>().loadPopular(),
          ),
        MovieHomeLoadStatus.empty => const Center(
            child: Text(
              '인기 영화가 없어요.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        MovieHomeLoadStatus.success => _HomeContent(
            popularMovies: viewModel.popularMovies,
          ),
      },
    );
  }
}

/// [Success] 추천 카드 + 인기 영화 5개.
class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.popularMovies});

  /// Popular 첫 페이지의 앞 5개 (1개 이상).
  final List<TmdbMovieDto> popularMovies;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Text(
            '오늘은 어떤\n영화를 볼까요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        _FeaturedCard(movie: popularMovies.first),
        SectionHeader(
          title: '인기 영화',
          // go: 탭(Route 위치)을 영화 목록으로 전환한다.
          onMoreTap: () => context.go('/movies'),
        ),
        _PopularMovieList(movies: popularMovies),
      ],
    );
  }
}

/// 홈 상단의 추천 영화 카드.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.movie});

  final TmdbMovieDto movie;

  void _openDetail(BuildContext context) {
    context.push('/movies/${movie.id}', extra: movie);
  }

  /// "2024 · ★ 4.3" (출시일이 없으면 연도는 빼고 보여준다)
  String get _subtitle {
    final year = releaseYear(movie.releaseDate);
    final rating = toFivePointRating(movie.voteAverage).toStringAsFixed(1);
    return [?year, '★ $rating'].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(context),
        child: SizedBox(
          height: 440,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TmdbPosterImage(
                  posterPath: movie.posterPath,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // 글자가 잘 보이도록 아래쪽을 어둡게 덮는다.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '추천 신작',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => _openDetail(context),
                        icon: const Icon(Icons.info, size: 18),
                        label: const Text('상세보기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가로로 스크롤되는 인기 영화 목록 (ListView.separated).
class _PopularMovieList extends StatelessWidget {
  const _PopularMovieList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 110,
            child: MovieCard(movie: movies[index], rank: index + 1),
          );
        },
      ),
    );
  }
}