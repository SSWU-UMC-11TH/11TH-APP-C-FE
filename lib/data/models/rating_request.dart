/// 서버 score는 1~5 정수만 허용합니다. 반 점·범위 밖 값은 조용히 바꾸지 않고 막습니다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// POST /v6/members/{memberId}/ratings 요청 body
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// 5주차 TmdbMovieDto.id (영화 배열 index가 아닙니다)
  final int movieId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'score': score,
        // 후기는 선택 항목이라 비어 있으면 아예 보내지 않습니다.
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
      };
}
