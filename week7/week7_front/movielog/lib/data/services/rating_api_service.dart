import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// [6~7주차] 회원별 평점 조회·등록·수정·삭제 API를 호출하는 Service.
///
/// API마다 성공 응답 계약이 다르다.
/// - 조회 GET: 200 + 직접 배열
/// - 등록 POST: 201 + 공통 응답 (result는 확정 전이라 파싱하지 않는다)
/// - 수정 PATCH: 200 + 공통 응답 (result null)
/// - 삭제 DELETE: 204 + body 없음 (JSON으로 파싱하지 않는다)
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 없으면 빈 배열이 오며, 이것은 실패가 아니다.
  /// memberId 형식 오류(400)와 없는 유저(404)는 DioException으로 전달된다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 201을 성공으로 처리한다. result의 숫자/null 계약은 확인 전 파싱하지 않는다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// PATCH지만 score는 필수다.
  /// comment를 생략하면 기존 후기가 null로 덮이므로, 유지하려면 기존 값을 그대로 보낸다.
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

  /// 204는 body가 없으므로 `response.data`를 읽지 않는다.
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

/// [6주차] 조회 GET의 400·404·그 밖의 실패를 서로 다른 문구로 바꾼다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// [7주차] 쓰기 API 오류는 서버 `message`를 그대로 보여준다.
///
/// 같은 COMMON404라도 등록에서는 "유저", 수정·삭제에서는 "평점"을 가리키므로
/// code만 보고 문구를 새로 만들지 않는다.
String writeErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// [7주차] code는 문구가 아니라 "다시 조회할지"를 정하는 데만 쓴다.
///
/// 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춘다.
/// 400(별점 범위)과 409(중복 등록)는 값만 고치거나 다시 시도하면 되므로 다시 조회하지 않는다.
bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] as String? : null;
  return code == 'COMMON403' || code == 'COMMON404';
}