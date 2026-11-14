import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/user_facing_exception.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// "내가 등록한 평점" 화면 전용 ViewModel (조회·수정·삭제).
/// 자체 백엔드에서 평점을 받고, movieId(TMDB id)로 영화 제목·포스터를 붙입니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;

  /// 회원가입 결과로 받은 학습용 memberId (LearningMemberSession에서 전달).
  /// 로그인 인증이 아닙니다. JWT 주차에서 토큰으로 바뀝니다.
  final int memberId;

  /// 같은 movieId는 TMDB에 한 번만 묻습니다. (null = TMDB에 없는 영화)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  /// 저장(수정·삭제)은 성공했지만 직후 GET 재조회가 실패했을 때의 안내.
  /// 저장 실패와 구분하기 위해 message와 따로 둡니다.
  String? refreshWarning;

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
      refreshWarning = null; // 조회가 성공하면 재조회 안내도 지웁니다.
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

  /// 쓰기 성공 뒤 목록을 서버 상태와 맞춥니다.
  /// GET 실패는 저장 실패로 다시 던지지 않고 refreshWarning으로만 알립니다.
  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  /// PATCH: score는 항상, comment는 유지/삭제 의도를 명시해서 보냅니다.
  /// (comment를 빼면 기존 후기가 null로 덮입니다)
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      await _handleWriteError(error);
    }
    if (_disposed) return; // 화면을 떠난 뒤의 결과는 반영하지 않습니다.
    await _refreshAfterWrite();
  }

  /// DELETE: 204는 body가 없으므로 파싱하지 않습니다.
  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      await _handleWriteError(error);
    }
    if (_disposed) return;
    // 마지막 항목을 지웠다면 load()가 빈 배열을 받아 Empty 상태가 됩니다.
    await _refreshAfterWrite();
  }

  /// 쓰기 실패: 403(남의 평점)·404(평점 없음)는 목록이 서버와 어긋났다는 뜻이라 다시 조회하고,
  /// 400·409는 재조회 없이 서버 message를 Dialog로 돌려보냅니다.
  Future<Never> _handleWriteError(DioException error) async {
    final message = writeErrorMessage(error);
    debugPrint(
      '[MyRatingsViewModel] 쓰기 실패 status=${error.response?.statusCode}',
    );
    if (!_disposed && shouldRefreshAfterRatingError(error)) await load();
    // Dialog가 잡아서 문구를 보여주고 입력을 유지합니다.
    throw UserFacingException(message);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
