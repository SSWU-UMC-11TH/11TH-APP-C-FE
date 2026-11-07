import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 워크북 자체 백엔드 전용 Dio Client.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않습니다.
Dio createMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'accept': 'application/json'},
    ),
  );

  // 요청·응답 확인용 로그는 debug 모드에서만 출력합니다.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        responseBody: true,
        logPrint: (log) => debugPrint('[MovieLog API] $log'),
      ),
    );
  }

  return dio;
}
