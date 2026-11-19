import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

/// 이번 로그인 세션에서 등록한 평점을 보관합니다.
/// v7에는 토큰 기반 내 평점 전체 조회 API가 없어서 재시작 뒤 복원하지 않습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this._auth)
      : _boundVersion = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final AuthViewModel _auth;
  final Map<int, TmdbMovieDto?> _movieCache = {};

  int _boundVersion;
  bool _disposed = false;
  bool _isUpdating = false;

  List<RatingWithMovie> ratings = const [];
  bool isDeleting = false;

  bool get isBusy => isDeleting || _isUpdating;

  // 세션이 바뀌면(로그아웃, 만료, 다른 계정 로그인) 이전 데이터와 요청 상태 정리
  void _onAuthChanged() {
    if (_auth.sessionVersion == _boundVersion) return;
    _boundVersion = _auth.sessionVersion;
    ratings = const [];
    isDeleting = false;
    _isUpdating = false;
    _notify();
  }

  /// 등록 성공 응답의 Rating을 바로 목록에 추가
  void addRating(RatingDto rating) {
    final version = _boundVersion;
    ratings = [
      RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
      ...ratings,
    ];
    _notify();
    if (!_movieCache.containsKey(rating.movieId)) {
      _fillMovie(rating.movieId, version);
    }
  }

  Future<void> _fillMovie(int movieId, int version) async {
    try {
      _movieCache[movieId] = await _movieService.findMovieById(movieId);
    } on DioException {
      return; // 일시 실패는 캐시하지 않음
    }
    if (_disposed || version != _boundVersion) return;
    ratings = [
      for (final e in ratings)
        e.rating.movieId == movieId
            ? RatingWithMovie(rating: e.rating, movie: _movieCache[movieId])
            : e,
    ];
    _notify();
  }

  /// 실패하면 StateError(message)를 던집니다. Dialog가 입력을 유지한 채 보여줍니다.
  Future<void> updateRating({
    required RatingDto rating,
    required int score,
    String? comment,
  }) async {
    if (isBusy) throw StateError('요청을 처리하는 중입니다.');
    final version = _boundVersion;
    _isUpdating = true;
    try {
      final updated = await _service.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      );
      if (_disposed || version != _boundVersion) return; // 이전 세션 응답 무시
      ratings = [
        for (final e in ratings)
          e.rating.ratingId == updated.ratingId
              ? RatingWithMovie(rating: updated, movie: e.movie)
              : e,
      ];
      _notify();
    } on DioException catch (error) {
      throw StateError(await _handleError(error, rating, version));
    } catch (_) {
      throw StateError('수정하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      _isUpdating = false;
    }
  }

  /// 성공하면 null, 실패하면 보여줄 문구
  Future<String?> deleteRating(RatingDto rating) async {
    if (isBusy) return '요청을 처리하는 중입니다.';
    final version = _boundVersion;
    isDeleting = true;
    _notify();

    String? error;
    try {
      await _service.deleteRating(rating.ratingId);
      if (!_disposed && version == _boundVersion) {
        ratings =
            ratings.where((e) => e.rating.ratingId != rating.ratingId).toList();
      }
    } on DioException catch (e) {
      error = await _handleError(e, rating, version);
    } catch (_) {
      error = '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (version == _boundVersion) isDeleting = false;
    _notify();
    return error;
  }

  Future<String> _handleError(
      DioException error, RatingDto rating, int version) async {
    final code = apiErrorCode(error);
    final message = apiErrorMessage(error);
    if (isSessionExpiredCode(code)) {
      await _auth.expireSession(); // 401만 세션 정리
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    }
    if (code == 'RATING404_1') {
      // 서버에 없는 평점이므로 화면 목록에서도 제거(새로고침과 같은 효과)
      if (version == _boundVersion) {
        ratings =
            ratings.where((e) => e.rating.ratingId != rating.ratingId).toList();
        _notify();
      }
      return message ?? '존재하지 않는 평점입니다.';
    }
    if (code == 'RATING403_1') {
      return message ?? '본인이 작성한 평점만 변경할 수 있어요.'; // 로그아웃 안 함
    }
    return message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}