import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_rating_store.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty }

/// [6~8주차] '내가 등록한 평점' 화면 전용 ViewModel.
///
/// 평점 기록은 자체 백엔드가 주인이므로, TMDB에서 영화 정보를 찾지 못해도
/// 평점 기록은 목록에 남기고 제목·포스터만 placeholder로 보여준다.
///
/// [8주차] memberId를 받지 않는다. 누구의 요청인지는 토큰으로 서버가 판단한다.
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없으므로, 목록은 현재 세션에서 등록한
/// 평점(SessionRatingStore)이고 수정·삭제 결과도 v7 응답으로 그 목록에 반영한다.
///
/// - AUTH401_2/3/4: expireSession()으로 세션을 정리한다. (Router가 /login으로 보낸다)
/// - 403·409·400: 안내만 하고 로그인 상태를 유지한다.
/// - 로그아웃·회원 전환 뒤 늦게 도착한 이전 응답은 화면에 반영하지 않는다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._store,
    this._auth,
  );

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingStore _store;
  final AuthViewModel _auth;

  /// 같은 movieId는 TMDB에 한 번만 묻는다. (404로 못 찾은 영화는 null로 캐시)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// Snackbar·목록 위 안내로 보여줄 문구. 세션 만료일 때는 비워 둔다.
  String? message;

  // ─────────────── [7주차 Challenge] 다중 선택 삭제 ───────────────
  bool isEditMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  /// 요청을 보낸 뒤 세션이 바뀌었으면(로그아웃·만료·회원 전환) 그 응답은 버린다.
  bool _isStale(int sessionVersion) {
    return _disposed || sessionVersion != _auth.sessionVersion;
  }

  bool hasRating(int ratingId) => _store.contains(ratingId);

  /// 현재 세션의 평점에 movieId로 TMDB 영화 정보를 붙여 목록을 만든다.
  Future<void> load() async {
    final version = ++_requestVersion;
    if (ratings.isEmpty) status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    final rawRatings = _store.ratings;
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
    status = entries.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    if (missingMovies > 0) {
      message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    }
    // 목록에서 사라진 평점은 선택에서도 뺀다. 목록이 비면 편집 모드도 끝낸다.
    final ids = entries.map((entry) => entry.rating.ratingId).toSet();
    selectedRatingIds.removeWhere((id) => !ids.contains(id));
    if (entries.isEmpty) isEditMode = false;
    notifyListeners();
  }

  /// [8주차] 쓰기 실패 처리. 문구는 Snackbar로 보여줄 수 있게 message에 남긴다.
  Future<void> _handleWriteError(
    DioException error,
    int sessionVersion, {
    required int ratingId,
  }) async {
    if (_isStale(sessionVersion)) return;
    final code = apiErrorCode(error);

    if (isSessionExpiredCode(code)) {
      // 세션 만료: 안내와 이동은 로그인 화면과 Router가 처리한다.
      message = null;
      await _auth.expireSession();
      return;
    }

    final errorMessage = ratingErrorMessage(error);
    if (code == 'RATING404_1') {
      // 서버에 없는 평점이므로 목록에서도 빼고 다시 그린다.
      _store.remove(ratingId);
      await load(); // load()가 message를 지우므로 실패 문구는 그 뒤에 남긴다.
      if (_isStale(sessionVersion)) return;
    }
    message = errorMessage;
    notifyListeners();
  }

  /// PATCH는 전체 교체다. score는 항상 보내고, comment는 Dialog에서 받은 값을 그대로 보낸다.
  /// (기존 코멘트를 그대로 두면 기존 값이, 지우면 null이 전달된다)
  ///
  /// 성공하면 수정 result의 Rating 객체로 카드를 갱신하고 true를 반환한다.
  Future<bool> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final sessionVersion = _auth.sessionVersion;
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (_isStale(sessionVersion)) return false;
      _store.replace(updated);
      await load();
      return true;
    } on DioException catch (error) {
      await _handleWriteError(error, sessionVersion, ratingId: ratingId);
      return false;
    } on StateError {
      // 200이지만 result가 없는 것처럼 예상하지 못한 응답
      if (_isStale(sessionVersion)) return false;
      message = '수정 결과를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      notifyListeners();
      return false;
    }
  }

  /// v7 삭제 성공은 result가 null인 200 응답이다. 성공하면 목록에서 뺀다.
  Future<bool> deleteRating(int ratingId) async {
    final sessionVersion = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
      if (_isStale(sessionVersion)) return false;
      _store.remove(ratingId);
      await load();
      return true;
    } on DioException catch (error) {
      await _handleWriteError(error, sessionVersion, ratingId: ratingId);
      return false;
    } on StateError {
      if (_isStale(sessionVersion)) return false;
      message = '삭제 결과를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      notifyListeners();
      return false;
    }
  }

  // ─────────────── [7주차 Challenge] 다중 선택 삭제 ───────────────

  void enterEditMode() {
    if (isDeletingSelected) return;
    isEditMode = true;
    selectedRatingIds.clear();
    notifyListeners();
  }

  /// "취소": 선택을 해제하고 기본 목록으로 돌아간다.
  void exitEditMode() {
    if (isDeletingSelected) return;
    isEditMode = false;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) {
      selectedRatingIds.add(ratingId);
    }
    notifyListeners();
  }

  /// 선택된 ratingId마다 삭제 API를 순서대로 호출한다.
  ///
  /// 실패한 항목은 선택 상태를 유지하고, 성공한 항목만 선택에서 뺀다.
  /// 원본 Set을 돌면서 remove하면 ConcurrentModificationError가 나므로 toList()로 복사해 돈다.
  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    final sessionVersion = _auth.sessionVersion;
    isDeletingSelected = true;
    message = null;
    notifyListeners();
    var failed = 0;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(ratingId);
          if (_isStale(sessionVersion)) return;
          selectedRatingIds.remove(ratingId);
          _store.remove(ratingId);
        } on DioException catch (error) {
          if (_isStale(sessionVersion)) return;
          final code = apiErrorCode(error);
          if (isSessionExpiredCode(code)) {
            // 세션 만료: 남은 요청을 보내지 않고 세션을 정리한다.
            await _auth.expireSession();
            return;
          }
          if (code == 'RATING404_1') {
            // 이미 서버에 없는 평점이므로 목록에서도 뺀다.
            selectedRatingIds.remove(ratingId);
            _store.remove(ratingId);
          } else {
            failed++; // 실패한 항목은 선택 상태를 유지한다.
          }
        } on StateError {
          failed++;
        }
      }
    } finally {
      isDeletingSelected = false;
      // 예상하지 못한 오류에도 로딩을 해제한다.
      if (!_disposed) notifyListeners();
    }
    if (_isStale(sessionVersion)) return;
    // 모두 지웠으면 편집 모드를 끝내고 기본 목록으로 돌아간다.
    if (failed == 0) isEditMode = false;
    await load();
    if (_isStale(sessionVersion)) return;
    if (failed > 0) {
      message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
