import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

/// [6주차] 평점 기록 하나와 그 movieId로 찾은 TMDB 영화 정보를 한 쌍으로 묶는다.
class RatingWithMovie {
  const RatingWithMovie({
    required this.rating,
    this.movie,
  });

  final RatingDto rating;

  /// TMDB에서 찾지 못했으면 null이다. 이때도 평점 기록은 화면에 남긴다.
  final TmdbMovieDto? movie;
}
