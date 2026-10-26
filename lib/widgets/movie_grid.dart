import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/movie_card.dart';

class MovieGrid extends StatelessWidget {
  final List<TmdbMovieDto> movies;
  final Map<int, String> genreNames;

  const MovieGrid({
    super.key,
    required this.movies,
    this.genreNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final genreLabel =
            movie.genreIds.isEmpty ? null : genreNames[movie.genreIds.first];
        return MovieCard(movie: movie, genreLabel: genreLabel);
      },
    );
  }
}