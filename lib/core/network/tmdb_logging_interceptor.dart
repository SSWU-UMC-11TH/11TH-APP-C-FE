import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// TMDB Client를 거치는 모든 요청·응답·오류를 같은 형식으로 기록합니다.
/// Authorization 값은 마스킹해서 Token이 로그에 남지 않게 합니다.
class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final maskedHeaders = Map<String, dynamic>.from(options.headers);
    if (maskedHeaders.containsKey('Authorization')) {
      maskedHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
    debugPrint('[TMDB 요청 Header] $maskedHeaders');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[TMDB 요청 Query] ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[TMDB 응답 Body] ${_summarize(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[TMDB 오류] ${err.requestOptions.uri}');
    debugPrint(
      '[TMDB 오류 내용] ${err.response?.statusCode ?? '-'} ${err.type.name} '
      '${err.message ?? ''}',
    );
    handler.next(err);
  }

  /// 응답 Body가 길면 콘솔이 잘리므로 앞부분만 출력합니다.
  String _summarize(Object? data) {
    final text = '$data';
    const maxLength = 800;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (총 ${text.length}자)';
  }
}
