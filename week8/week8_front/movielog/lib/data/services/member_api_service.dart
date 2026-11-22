import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// [8주차] 내 정보 조회·수정 API. 보호 Client(AuthInterceptor 등록)를 받는다.
///
/// 누구의 요청인지는 path의 memberId가 아니라 Authorization Header로 서버가 판단한다.
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// 성공 응답이 이미 최신 내 정보이므로 GET me를 다시 호출할 필요가 없다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
