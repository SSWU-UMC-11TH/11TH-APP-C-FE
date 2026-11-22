import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// [8주차] MovieLog 보호 API에만 `Authorization: Bearer {JWT}`를 붙이는 Interceptor.
///
/// 보호용 Client(createAuthMovieLogClient)에만 등록한다.
/// host와 path를 함께 확인하므로 다른 서버나 공개 경로에는 토큰이 실리지 않는다.
/// 토큰 문자열은 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  bool _isProtected(RequestOptions options) {
    final path = options.uri.path;
    return options.uri.host == 'workbook.devnoco.com' &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    options.headers.remove('Authorization'); // 이전 요청의 토큰을 재사용하지 않는다.
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
