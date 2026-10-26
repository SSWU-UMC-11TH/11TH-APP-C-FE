import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class PopularMovieCard extends StatelessWidget {
  final TmdbMovieDto movie;
  final int rank;

  const PopularMovieCard({super.key, required this.movie, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: TmdbPosterImage(
                      posterPath: movie.posterPath,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$rank',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFD4A52C)),
                const SizedBox(width: 2),
                Text(movie.voteAverage.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}