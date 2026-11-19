import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입 관련 v6 API (구 MemberCheckService).
/// HTTP 요청과 DTO 변환만 담당합니다(stateless).
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// GET /v6/members/nickname/{nickname} → 사용 가능하면 true
  /// 성공은 공통 형식 없이 { "available": bool }을 그대로 반환합니다.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// GET /v6/members/email/{email} → 사용 가능하면 true
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// POST /v6/members → 201 + CommonResponse<SignUpResult>
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post(
      '/v6/members',
      data: request.toJson(),
    );

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 실패 응답의 message를 그대로 사용합니다.
/// (서버 message가 이미 사용자에게 보여줄 수 있는 문장입니다)
String writeSignUpErrorMessage(DioException error) {
  final common = CommonResponse.tryParseError(error.response?.data);
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
