import 'movie.dart';

/// Mock 요청 결과를 바꿔보기 위한 모드.
enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

/// 실제 API 대신 Future.delayed로 비동기 결과를 흉내 내는 Service.
/// 화면은 이 Service가 Mock인지 실제 API인지 몰라도 되도록
/// `Future<List<Movie>> fetchMovies()` 경계만 사용합니다.
class FakeMovieService {
  const FakeMovieService();

  // TODO(5주차 유저별 평점 조회 API): 실제 API Service로 교체합니다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // Loading 화면이 최소 800ms 이상 보이도록 1초 기다립니다.
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure =>
        throw const MovieLoadException('영화를 불러오지 못했습니다.'),
    };
  }
}
