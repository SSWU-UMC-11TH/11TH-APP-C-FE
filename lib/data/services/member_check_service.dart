import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// v5 닉네임·이메일 중복 확인 API. HTTP 요청과 DTO 변환만 담당합니다(stateless).
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// GET /v5/members/nickname/{nickname} → 사용 가능하면 true
  Future<bool> checkNickname(String nickname) async {
    // 한글·특수문자도 안전하게 경로에 넣도록 인코딩합니다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// GET /v5/members/email/{email} → 사용 가능하면 true
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
