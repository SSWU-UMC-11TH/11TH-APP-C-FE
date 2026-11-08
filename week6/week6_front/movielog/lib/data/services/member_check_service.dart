import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// [6주차] 닉네임·이메일 중복 확인 API를 호출하는 Service.
///
/// 상태를 갖지 않으므로 앱 최상단 MultiProvider에 한 번만 등록해 공유한다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
