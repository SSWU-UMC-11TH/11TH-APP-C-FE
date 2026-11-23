import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'MovieLog'),
      body: Consumer<MovieHomeViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MovieHomeLoadStatus.idle ||
            MovieHomeLoadStatus.loading => const MovieListLoading(),
            MovieHomeLoadStatus.error => MovieListError(
                message: viewModel.message,
                onRetry: () => context.read<MovieHomeViewModel>().loadPopular(),
              ),
            MovieHomeLoadStatus.empty =>
              const MovieListEmpty(message: '인기 영화가 없어요.'),
            MovieHomeLoadStatus.success =>
              _HomeContent(popularMovies: viewModel.popularMovies),
          };
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.popularMovies});

  final List<TmdbMovieDto> popularMovies;

  @override
  Widget build(BuildContext context) {
    // success 상태일 때만 그려지므로 popularMovies는 비어 있지 않습니다.
    final featured = popularMovies.first;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FeaturedMovie(movie: featured),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('인기 영화', style: AppTextStyles.titleMedium),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: popularMovies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 130,
                child: MovieCard(movie: popularMovies[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 오늘의 추천: 인기 1위 영화를 가로 이미지(backdrop)로 크게 보여줍니다.
class FeaturedMovie extends StatelessWidget {
  const FeaturedMovie({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: TmdbPosterImage(
                // backdrop이 없으면 포스터로 대신합니다.
                posterPath: movie.backdropPath ?? movie.posterPath,
                width: double.infinity,
                height: double.infinity,
                size: 'w780',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('오늘의 추천', style: AppTextStyles.bodySmall),
          Text(movie.title, style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}
