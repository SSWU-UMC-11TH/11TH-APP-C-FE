import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';

/// 홈과 영화 목록에서 함께 쓰는 영화 카드.
/// 부모가 높이를 정해줘야 합니다 (GridView 칸, SizedBox 등).
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // push: 현재 화면 위에 상세를 쌓음 → 뒤로가기로 돌아올 수 있음
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                movie.posterAsset,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium,
          ),
          Text('${movie.genre} · ${movie.year}', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
