import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// [6~7주차] '내가 등록한 평점' 화면 전용 ViewModel.
///
/// 평점 기록은 자체 백엔드가 주인이므로, TMDB에서 영화 정보를 찾지 못해도
/// 평점 기록은 목록에 남기고 제목·포스터만 placeholder로 보여준다.
///
/// [7주차] memberId는 회원가입 결과를 보관한 LearningMemberSession에서 받는다.
/// 인증된 '내 계정'이 아닌 학습용 식별자다. (실제 회원 식별은 JWT 주차에서 바뀐다)
/// 조회·수정·삭제를 이 화면에서 하고, 쓰기 성공 뒤에는 목록을 다시 조회한다.
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

  /// [7주차] 저장은 성공했지만 그 뒤 GET 재조회만 실패했을 때의 안내.
  String? refreshWarning;

  // ─────────────── [Challenge] 다중 선택 삭제 ───────────────
  bool isEditMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

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
      // 조회에 성공했으면 "조회만 다시 시도" 안내는 더 이상 필요 없다.
      refreshWarning = null;
      // 목록에서 사라진 평점은 선택에서도 뺀다. 목록이 비면 편집 모드도 끝낸다.
      final ids = entries.map((entry) => entry.rating.ratingId).toSet();
      selectedRatingIds.removeWhere((id) => !ids.contains(id));
      if (entries.isEmpty) isEditMode = false;
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// [7주차] 쓰기 성공 뒤 목록을 다시 읽는다.
  /// GET 실패는 저장 실패와 다른 상태이므로 다시 던지지 않고 안내만 남긴다.
  Future<void> _refreshAfterWrite() async {
    await load(); // load()는 GET 실패를 status=error로 기록한다.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    } else {
      refreshWarning = null;
    }
  }

  /// [7주차] 쓰기 실패 처리.
  ///
  /// 서버 message를 그대로 안내하고, 403·404면 목록을 다시 읽어 서버 상태와 맞춘다.
  /// load()가 message를 지우므로 재조회가 끝난 뒤에 실패 문구를 남긴다.
  Future<void> _handleWriteError(DioException error) async {
    final errorMessage = writeErrorMessage(error);
    if (shouldRefreshAfterRatingError(error)) await load();
    if (_disposed) return;
    message = errorMessage;
    notifyListeners();
  }

  /// score는 항상 보내고, comment는 Dialog에서 받은 값을 그대로 보낸다.
  /// (기존 코멘트를 그대로 두면 기존 값이, 지우면 null이 전달된다)
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
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리한다.
    }
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않는다.
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      await _handleWriteError(error);
      rethrow;
    }
    await _refreshAfterWrite();
  }

  // ─────────────── [Challenge] 다중 선택 삭제 ───────────────

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
    isDeletingSelected = true;
    notifyListeners();
    var failed = 0;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
          // 실패한 항목은 선택 상태를 유지한다.
        }
      }
    } finally {
      isDeletingSelected = false;
      // 예상하지 못한 오류에도 로딩을 해제한다.
      if (!_disposed) notifyListeners();
    }
    if (_disposed) return;
    // 모두 지웠으면 편집 모드를 끝내고 기본 목록으로 돌아간다.
    if (failed == 0) isEditMode = false;
    await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리한다.
    if (_disposed) return;
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
