import '../data/mock_movie.dart';
import 'package:movielog/models/movie.dart';

/// 테스트용 동작 모드. 아래 movieService의 mode만 바꿔서 상태를 확인합니다.
enum FakeMovieMode { success, empty, error }

class FakeMovieService {
  const FakeMovieService({this.mode = FakeMovieMode.success});

  final FakeMovieMode mode;

  // TODO(5주차 유저별 평점 조회 API): 실제 API 호출로 교체
  Future<List<Movie>> fetchMovies() async {
    await Future.delayed(const Duration(seconds: 1));

    switch (mode) {
      case FakeMovieMode.success:
        return mockMovies;
      case FakeMovieMode.empty:
        return [];
      case FakeMovieMode.error:
        throw Exception('fake network error');
    }
  }
}

const movieService = FakeMovieService(mode: FakeMovieMode.success);