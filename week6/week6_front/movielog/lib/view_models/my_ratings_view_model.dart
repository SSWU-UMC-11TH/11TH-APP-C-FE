import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

/// 인증된 '내 계정'이 아닌 학습용 데이터입니다. (실제 회원 식별은 JWT 주차에서 바뀐다)
const int sampleMemberId = 999999;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// [6주차] '내가 등록한 평점' 화면 전용 ViewModel.
///
/// 평점 기록은 자체 백엔드가 주인이므로, TMDB에서 영화 정보를 찾지 못해도
/// 평점 기록은 목록에 남기고 제목·포스터만 placeholder로 보여준다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  /// 같은 movieId는 TMDB에 한 번만 묻는다. (404로 못 찾은 영화는 null로 캐시)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않는다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] =
                await _movieService.findMovieById(rating.movieId);
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않는다. 다음 로딩에서 재시도한다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;

      ratings = entries;
      // 빈 배열은 실패가 아니라 Empty 상태다.
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
