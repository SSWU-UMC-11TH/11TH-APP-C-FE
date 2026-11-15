import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_poster.dart';

/// 포스터 + 제목 + 보조 정보로 이루어진 공통 영화 카드.
///
/// - 영화 목록(Grid): 포스터 오른쪽 위에 평점 배지, 아래에 "2024 · 드라마"
/// - 홈 인기 영화   : [rank]를 주면 왼쪽 위에 순위 배지, 아래에 별점
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.rank});

  final Movie movie;

  /// null이 아니면 홈의 인기 영화용 작은 카드로 그린다.
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final isRanked = rank != null;

    return GestureDetector(
      // 글자 사이 빈 영역을 눌러도 Tap이 잡히도록 한다.
      behavior: HitTestBehavior.opaque,
      // push: 현재 화면을 유지한 채 상세를 위에 쌓는다 → 뒤로 가기 가능.
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MoviePoster(movie: movie),
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
                    child: _PosterBadge(
                      text: '★ ${movie.rating.toStringAsFixed(1)}',
                    ),
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
                  movie.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            )
          else
            Text(
              '${movie.year} · ${movie.genre}',
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