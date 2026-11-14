import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};

  int _requestVersion = 0;
  bool _disposed = false;
  bool _isUpdating = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  bool isDeleting = false;

  /// 수정·삭제 요청 중에는 화면을 벗어나지 못하게 막는 데 사용
  bool get isBusy => isDeleting || _isUpdating;

  /// afterWrite: 저장은 성공했고 목록 재조회(GET)만 하는 경우
  Future<void> load({bool afterWrite = false}) async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    _notify();

    const afterWriteMessage = '저장은 완료됐지만 목록을 불러오지 못했어요. 다시 시도해 주세요.';

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;

        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] =
                await _movieService.findMovieById(rating.movieId);
          } on DioException {
            // 일시적 실패는 캐시하지 않고 다음 로딩에서 재시도
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
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message =
          afterWrite ? afterWriteMessage : writeMyRatingsErrorMessage(error);
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message =
          afterWrite ? afterWriteMessage : '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    _notify();
  }

  /// 성공하면 정상 종료, 실패하면 StateError(message)를 던집니다.
  /// Dialog가 이 오류를 받아 입력을 유지한 채 문구를 보여줍니다.
  Future<void> updateRating({
    required RatingDto rating,
    required int score,
    String? comment,
  }) async {
    if (isBusy) throw StateError('요청을 처리하는 중입니다.');
    _isUpdating = true;

    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      final errorMessage = writeErrorMessage(error);
      _isUpdating = false;
      if (shouldRefreshAfterRatingError(error) && !_disposed) {
        await load(); // 목록이 서버 상태와 어긋난 경우 맞춤
      }
      throw StateError(errorMessage);
    } catch (_) {
      _isUpdating = false;
      throw StateError('수정하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }

    _isUpdating = false;
    if (_disposed) return;
    await load(afterWrite: true); // 저장 성공 뒤 GET. 실패해도 수정 성공은 유지
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 문구를 반환합니다.
  Future<String?> deleteRating(RatingDto rating) async {
    if (isBusy) return '요청을 처리하는 중입니다.';
    isDeleting = true;
    _notify();

    String? errorMessage;
    var success = false;

    try {
      await _service.deleteRating(memberId: memberId, ratingId: rating.ratingId);
      success = true;
    } on DioException catch (error) {
      errorMessage = writeErrorMessage(error);
      if (shouldRefreshAfterRatingError(error) && !_disposed) {
        await load();
      }
    } catch (_) {
      errorMessage = '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (success && !_disposed) {
      await load(afterWrite: true); // 마지막 항목이면 Empty 상태가 됨
    }

    isDeleting = false;
    _notify();
    return errorMessage;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}