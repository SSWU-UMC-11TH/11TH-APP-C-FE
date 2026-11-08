import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_theme.dart';
import '../utils/movie_format.dart';
import 'tmdb_poster_image.dart';

/// 포스터 + 제목 + 보조 정보로 이루어진 공통 영화 카드.
///
/// - 영화 목록(Grid): 포스터 오른쪽 위에 평점 배지, 아래에 "2024 · 드라마"
/// - 홈 인기 영화   : [rank]를 주면 왼쪽 위에 순위 배지, 아래에 별점
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    this.rank,
    this.genreName,
  });

  final TmdbMovieDto movie;

  /// null이 아니면 홈의 인기 영화용 작은 카드로 그린다.
  final int? rank;

  /// Genre API로 찾은 첫 번째 장르 이름. 없으면 표시하지 않는다.
  final String? genreName;

  void _openDetail(BuildContext context) {
    // 배열 index가 아니라 TMDB id를 Path로 넘긴다. (이후 평점 movieId)
    // TMDB에는 상세 조회를 따로 하지 않으므로 받은 DTO를 extra로 함께 넘긴다.
    context.push('/movies/${movie.id}', extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    final isRanked = rank != null;
    final rating = toFivePointRating(movie.voteAverage).toStringAsFixed(1);
    // 출시일이 없으면 연도를, 장르를 모르면 장르를 빼고 이어 붙인다.
    final subtitleParts = <String>[];
    final year = releaseYear(movie.releaseDate);
    if (year != null) subtitleParts.add(year);
    final genre = genreName;
    if (genre != null) subtitleParts.add(genre);
    final subtitle = subtitleParts.join(' · ');

    return GestureDetector(
      // 글자 사이 빈 영역을 눌러도 Tap이 잡히도록 한다.
      behavior: HitTestBehavior.opaque,
      // push: 현재 화면을 유지한 채 상세를 위에 쌓는다 → 뒤로 가기 가능.
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TmdbPosterImage(
                    posterPath: null,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (isRanked)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _PosterBadge(text: '$rank'),
                  )
                else
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _PosterBadge(text: '★ $rating'),
                  ),
              ],
            ),
          ),
          SizedBox(height: isRanked ? 8 : 10),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isRanked ? 13 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (isRanked)
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            )
          else
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
        ],
      ),
    );
  }
}

/// 포스터 위에 얹는 어두운 배지 (순위, 평점).
class _PosterBadge extends StatelessWidget {
  const _PosterBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
