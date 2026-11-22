import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// [7주차] 6주차 MemberCheckService의 이름을 SignUpService로 바꿨다.
///
/// 닉네임·이메일 중복 확인과 회원가입 POST를 맡는다.
/// 상태를 갖지 않으므로 앱 최상단 MultiProvider에 한 번만 등록해 공유한다.
///
/// [8주차] path를 v7으로 바꿨다. 가입한 계정으로 `/v7/auth/login`에 로그인한다.
/// 토큰이 필요 없는 요청이므로 공개 Client(Interceptor 없음)를 받는다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 성공은 기존처럼 직접 객체(`{ "available": true }`)로 온다.
  /// 오류는 공통 응답 형식으로 감싸져 DioException으로 전달된다.
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v7/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v7/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 201 + 공통 응답. 공통 응답을 한 번 파싱한 뒤 `result`에서 회원가입 payload를 읽는다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post(
      '/v7/members',
      data: request.toJson(),
    );

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      // 201이면 가입은 끝난 것이다. result 모양이 달라도 가입 실패로 보지 않는다.
      (value) => value is Map<String, dynamic>
          ? SignUpResult.fromJson(value)
          : const SignUpResult(memberId: null, email: null, nickname: null),
    );
  }
}

/// [7주차] 회원가입 400·409는 서버 `message`에 이미 사용자에게 보여줄 문장이 있으므로
/// code별 문구를 새로 만들지 않고 그대로 쓴다.
String writeSignUpErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
