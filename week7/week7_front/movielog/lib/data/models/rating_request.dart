/// [7주차] 서버 평점은 1~5 사이 정수만 허용한다.
///
/// 별점 입력 위젯이 이미 정수 단위로 막아 주지만, 반 점 값이 조용히 잘리지 않도록
/// 남겨 두는 안전장치다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// [7주차] 평점 등록 요청 body (`POST /v6/members/{memberId}/ratings`).
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// 5주차 `TmdbMovieDto.id`. 영화 배열 index가 아니다.
  final int movieId;
  final int score;
  final String? comment;

  /// comment는 선택 항목이라 비어 있으면 빈 문자열 대신 생략한다.
  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'score': score,
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
      };
}
