import 'movie.dart';

/// 영화 목록 화면이 처음 그려질 때 필요한 값 묶음.
///
/// 영화 목록과 저장된 장르는 서로 의존하지 않으므로 `Future.wait`로
/// 함께 불러온 뒤 이 객체 하나로 전달한다.
class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.savedGenres,
  });

  final List<Movie> movies;

  /// 지난 실행에서 마지막으로 선택했던 장르. 없으면 빈 Set('전체').
  final Set<String> savedGenres;
}