import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';

/// [6주차 Guided Practice B-1] RatingDto.fromJson을 작은 JSON 조각으로 검증한다.
void main() {
  test('평점 JSON을 RatingDto로 바꾼다', () {
    final rating = RatingDto.fromJson({
      'ratingId': 12,
      'movieId': 550,
      'score': 5,
      'comment': '최고의 영화!',
      'createdAt': '2026-09-06T12:14:03.000Z',
      'updatedAt': '2026-09-06T12:14:03.000Z',
    });

    expect(rating.ratingId, 12);
    expect(rating.movieId, 550);
    expect(rating.score, 5);
    expect(rating.comment, '최고의 영화!');
    expect(rating.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
  });

  test('comment가 null이어도 변환된다', () {
    final rating = RatingDto.fromJson({
      'ratingId': 3,
      'movieId': 13,
      'score': 3,
      'comment': null,
      'createdAt': '2026-11-06T19:00:09.406Z',
      'updatedAt': '2026-11-06T19:00:09.406Z',
    });

    expect(rating.comment, isNull);
    expect(rating.score, 3);
  });
}
