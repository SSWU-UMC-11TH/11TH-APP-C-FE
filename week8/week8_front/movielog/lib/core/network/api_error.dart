// lib/core/network/api_error.dart — 인증·회원·평점 코드가 공통으로 import한다.
import 'package:dio/dio.dart';

/// [8주차] 서버 오류 응답 body의 `code`를 꺼낸다. (예: AUTH401_2, RATING403_1)
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// [8주차] 서버 오류 응답 body의 `message`를 꺼낸다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// [8주차] 보호 요청에서 토큰이 없거나(2)·무효이거나(3)·만료된(4) 경우만 세션 만료 후보다.
///
/// 로그인 입력 오류인 `AUTH401_1`과 권한 부족인 403은 여기에 포함하지 않는다.
bool isSessionExpiredCode(String? code) {
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
