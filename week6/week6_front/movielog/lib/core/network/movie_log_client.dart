import 'package:dio/dio.dart';

/// [6주차] 워크북 자체 백엔드(`/v5`) 전용 Dio Client.
///
/// TMDB Client(createTmdbClient)와 baseUrl·헤더가 다르므로 하나로 합치지 않는다.
Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
