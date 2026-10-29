import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

/// 홈 화면 전용 ViewModel. 인기 영화 중 앞 5개만 상태로 보관합니다.
class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  static const popularCount = 5;

  final TmdbMovieService _service;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;

  bool get isLoading => status == MovieHomeLoadStatus.loading;

  Future<void> loadPopular() async {
    if (isLoading) return;

    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // take(5): 결과가 5개보다 적어도 있는 만큼만 가져와 RangeError가 나지 않습니다.
      popularMovies = page.results.take(popularCount).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } catch (error) {
      // DioException(네트워크·401)뿐 아니라 파싱 오류도 Error 상태로 보여줍니다.
      debugPrint('[MovieHomeViewModel] 인기 영화 로드 실패: $error');
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    // 요청 중 화면을 떠나 dispose됐다면 알리지 않습니다.
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
