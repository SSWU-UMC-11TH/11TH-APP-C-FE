import '../data/mock_movies.dart';
import '../models/movie.dart';

/// Mock Service가 어떤 결과로 완료될지 정하는 값.
enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

/// 실제 API 대신 `Future.delayed`로 비동기 결과를 만드는 Service.
///
/// 화면은 `fetchMovies()`가 돌려주는 `Future<List<Movie>>`만 알면 되고,
/// 내부가 Mock인지 실제 네트워크 요청인지는 알 필요가 없다.
class FakeMovieService {
  const FakeMovieService();

  // TODO(5주차 유저별 평점 조회 API): Future.delayed와 Mock 목록을
  // Swagger v5의 실제 API 호출로 교체한다. 반환 타입은 그대로 유지한다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // Loading 화면이 800ms 이상 보이도록 1초 지연한다.
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure =>
        throw const MovieLoadException('영화를 불러오지 못했습니다.'),
    };
  }
}