/// [6주차] 유저별 평점 조회(`GET /v5/members/{memberId}/ratings`) 응답의 한 칸.
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;

  /// TMDB 영화 ID
  final int movieId;
  final int score;

  /// API 명세에서 nullable이므로 값이 없을 수 있다.
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
