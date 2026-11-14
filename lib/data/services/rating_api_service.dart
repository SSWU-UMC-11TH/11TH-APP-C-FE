import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// v6 평점 API: 조회·등록·수정·삭제
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// GET /v6/members/{memberId}/ratings
  /// 성공은 공통 형식 없이 배열을 그대로 반환합니다. (결과가 없으면 빈 배열)
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /v6/members/{memberId}/ratings → 201 + wrapper
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 201을 성공으로 처리합니다.
    // 명세의 result(ratingId 숫자 / 예시 null)가 확정되지 않아 result!로 강제 파싱하지 않고,
    // 등록 뒤에는 GET으로 목록을 다시 확인합니다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// PATCH /v6/members/{memberId}/ratings/{ratingId} → 200 + result null
  /// comment를 생략하면 기존 후기가 null로 덮이므로 항상 명시적으로 보냅니다.
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  /// DELETE /v6/members/{memberId}/ratings/{ratingId} → 204 (body 없음)
  /// 204 응답 body는 JSON으로 파싱하지 않습니다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 쓰기 실패: 서버 message를 그대로 보여줍니다.
/// (같은 COMMON404라도 등록은 "유저", 수정·삭제는 "평점"을 가리키므로 문구를 새로 만들지 않습니다)
String writeErrorMessage(DioException error) {
  final common = CommonResponse.tryParseError(error.response?.data);
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 403·404는 화면의 목록이 서버 상태와 어긋났다는 뜻이라 목록을 다시 조회합니다.
/// 400(별점 범위)·409(중복 등록)는 값만 고쳐 다시 시도하면 되므로 재조회하지 않습니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.tryParseError(error.response?.data)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}

/// 평점 목록 조회(GET) 실패 문구
String writeMyRatingsErrorMessage(DioException error) {
  // v6 오류는 공통 형식이므로 서버 message가 있으면 우선 사용합니다.
  final common = CommonResponse.tryParseError(error.response?.data);
  if (common != null) return common.message;
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
