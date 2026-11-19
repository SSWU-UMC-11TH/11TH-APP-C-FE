/// v5 유저별 평점 조회 응답의 한 항목.
/// movieId는 TMDB 영화 id라서 TMDB API로 제목·포스터를 가져올 수 있습니다.
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;
  final int movieId;
  final int score;

  /// nullable: 후기를 남기지 않았으면 null
  final String? comment;
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) => RatingDto(
        ratingId: (json['ratingId'] as num).toInt(),
        movieId: (json['movieId'] as num).toInt(),
        score: (json['score'] as num).toInt(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
