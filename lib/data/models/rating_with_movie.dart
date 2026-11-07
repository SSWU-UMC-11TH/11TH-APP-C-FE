import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// 평점 한 건과 그 영화의 TMDB 정보를 한 쌍으로 묶은 모델.
class RatingWithMovie {
  const RatingWithMovie({
    required this.rating,
    this.movie,
  });

  final RatingDto rating;

  /// TMDB에서 찾지 못했으면 null → 화면에서 placeholder로 표시합니다.
  final TmdbMovieDto? movie;
}
