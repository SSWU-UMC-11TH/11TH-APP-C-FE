import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

/// 로그인 기능이 없는 6주차에는 학습용 memberId 1의 공개 평점을 조회합니다.
/// (인증된 '내 계정'이 아닙니다. JWT 주차에서 바뀝니다.)
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// "내가 등록한 평점" 화면 전용 ViewModel.
/// 자체 백엔드에서 평점을 받고, movieId(TMDB id)로 영화 제목·포스터를 붙입니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;

  /// 조회 대상 회원. 기본은 [sampleMemberId]이고,
  /// debug 모드에서만 Empty·Error 확인용으로 바꿀 수 있습니다.
  int memberId;

  /// 같은 movieId는 TMDB에 한 번만 묻습니다. (null = TMDB에 없는 영화)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  bool _isStale(int version) => _disposed || version != _requestVersion;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_isStale(version)) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      for (final rating in rawRatings) {
        if (_isStale(version)) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] =
                await _movieService.findMovieById(rating.movieId);
          } on DioException {
            // 일시적인 TMDB 실패는 캐시하지 않습니다. 다음 로딩에서 다시 시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        // 영화 정보가 없어도 평점 기록은 그대로 남깁니다.
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_isStale(version)) return;

      ratings = entries;
      // 빈 배열은 실패가 아니라 Empty 상태입니다.
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_isStale(version)) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (error) {
      // 응답 모양이 예상과 다를 때(파싱 오류)도 Loading에 멈추지 않게 합니다.
      if (_isStale(version)) return;
      debugPrint('[MyRatingsViewModel] 응답 처리 실패: $error');
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// debug 모드 전용: 다른 memberId로 Empty·Error 상태를 확인합니다.
  Future<void> changeMemberIdForDebug(int id) {
    memberId = id;
    return load();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
