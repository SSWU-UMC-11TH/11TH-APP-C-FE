import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

/// 홈 화면 전용 ViewModel. Popular 첫 페이지에서 앞 5개만 보관한다.
class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadPopular() async {
    status = MovieHomeLoadStatus.loading;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // 결과가 5개보다 적어도 take(5)는 있는 만큼만 돌려준다. ([0]~[4] 직접 접근 X)
      popularMovies = page.results.take(5).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException {
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    // 응답을 기다리는 동안 화면이 사라졌다면 알리지 않는다.
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
