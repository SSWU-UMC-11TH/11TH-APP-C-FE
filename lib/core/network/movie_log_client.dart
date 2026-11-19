import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_logging_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';

BaseOptions _movieLogOptions() => BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );

/// 공개 요청용: 로그인, 중복 확인, 유저별 평점 조회. 토큰 Interceptor 없음
Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}

/// 보호 요청용: 내 정보, 평점 등록/수정/삭제. 여기에만 Bearer를 붙임
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}