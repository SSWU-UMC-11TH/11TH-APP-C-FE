import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_text_styles.dart';
import 'tmdb_poster_image.dart';

/// "2024-05-01" → "2024". 날짜가 없으면 null (연도를 표시하지 않음).
String? releaseYearOf(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  return releaseDate.substring(0, 4);
}

/// 홈과 영화 목록에서 함께 쓰는 영화 카드.
/// 부모가 높이를 정해줘야 합니다 (GridView 칸, SizedBox 등).
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = releaseYearOf(movie.releaseDate);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 배열 index가 아니라 TMDB id를 Path Parameter로 넘깁니다.
      // extra로 이미 가진 DTO도 함께 넘겨 상세 화면에서 다시 요청하지 않게 합니다.
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
                size: 'w342',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium,
          ),
          Text(
            [
              if (year != null) year,
              '★ ${movie.voteAverage.toStringAsFixed(1)}',
            ].join(' · '),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
