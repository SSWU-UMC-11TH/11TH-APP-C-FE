import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// [8주차] 등록·수정 성공 응답의 `result`는 Rating 객체다. (v6에서는 ID?/null이었다)
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 공개 조회는 공통 응답으로 감싸지 않은 직접 배열이다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// [6~8주차] 평점 조회·등록·수정·삭제 API를 호출하는 Service.
///
/// [8주차] 같은 Service 안에서도 메서드에 따라 서로 다른 Client를 쓴다.
/// - 유저별 평점 조회: 공개 Client (토큰 없음, path에 memberId 유지)
/// - 등록·수정·삭제: 보호 Client (Interceptor가 Bearer Header를 붙인다)
///
/// v7 보호 요청에는 memberId를 보낼 자리가 없다. path·body·query 어디에도 넣지 않는다.
/// 누구의 요청인지는 서버가 Authorization Header로 판단한다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 조회: 직접 배열, 토큰 없음.
  ///
  /// v7 로그인·내 정보 응답에는 memberId가 없어서 로그인한 회원의 목록을 이 API로
  /// 복원할 수 없다. 화면의 '내가 등록한 평점'은 현재 세션에서 등록한 평점만 보여준다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post(
      '/v7/ratings',
      data: request.toJson(),
    );
    return parseRatingResult(response.data);
  }

  /// PATCH는 부분 수정이 아니라 전체 교체다.
  /// comment를 생략하면 서버에 null로 전달되어 기존 후기가 지워진다.
  /// Dialog를 열 때 기존 score·comment를 채워서 항상 두 값을 함께 보낸다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// v7 삭제 성공은 204가 아니라 result가 null인 200 응답이다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답');
    }
  }
}

/// [8주차] 평점 쓰기 오류를 도메인 code로 구분한다.
///
/// - RATING403_1: 본인이 작성한 평점이 아니다. 안내만 하고 로그아웃하지 않는다.
/// - RATING404_1: 존재하지 않는 평점이다.
/// - RATING409_1: 같은 영화에 이미 평점을 남겼다. 기존 기록을 확인하게 한다.
/// - COMMON400: 별점 범위(1~5) 같은 입력값 검증 실패. 서버 message를 그대로 보여준다.
///
/// AUTH401_2/3/4(세션 만료)는 문구가 아니라 세션 정리로 처리하므로 여기서 다루지 않는다.
String ratingErrorMessage(DioException error) {
  return switch (apiErrorCode(error)) {
    'RATING403_1' => '본인이 작성한 평점만 변경할 수 있어요.',
    'RATING404_1' => '존재하지 않는 평점이에요.',
    'RATING409_1' => '이미 평점을 남긴 영화예요. 기존 평점을 확인해 주세요.',
    'COMMON400' => apiErrorMessage(error) ?? '입력값을 다시 확인해 주세요.',
    _ => '요청에 실패했어요. 네트워크 상태를 확인하고 다시 시도해 주세요.',
  };
}
