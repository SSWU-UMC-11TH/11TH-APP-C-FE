import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';

class MovieLogLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[MovieLog 요청] ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
        '[MovieLog 응답] ${response.statusCode} ${response.requestOptions.uri.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        '[MovieLog 오류] ${err.response?.statusCode} ${apiErrorCode(err)} ${err.requestOptions.uri.path}');
    handler.next(err);
  }
}