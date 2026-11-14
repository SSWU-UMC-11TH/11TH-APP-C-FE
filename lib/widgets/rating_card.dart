import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class RatingCard extends StatelessWidget {
  final RatingWithMovie entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RatingCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final primary = Theme.of(context).colorScheme.primary;
    final comment = rating.comment?.trim();
    final date = rating.createdAt.toLocal().toString().substring(0, 10);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D2E0), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 80,
              height: 112,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 #${rating.movieId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '별점 ${rating.score} / 5',
                  style:
                      TextStyle(color: primary, fontWeight: FontWeight.w700),
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(comment),
                ],
                const SizedBox(height: 6),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          // 학습용 회원 본인의 평점에만 수정·삭제 표시
          if (onEdit != null || onDelete != null)
            Column(
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: '수정',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, color: primary),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: '삭제',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}