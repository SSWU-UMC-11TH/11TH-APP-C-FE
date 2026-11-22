import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_rating_store.dart';
import 'submit_status.dart';

/// [7~8주차] 영화 상세 화면 전용 ViewModel.
///
/// 현재 화면의 영화 DTO와 평점 "등록" 상태만 관리한다.
/// 수정·삭제는 마이페이지의 '내가 등록한 평점'(MyRatingsViewModel)에서 한다.
///
/// [8주차] memberId를 받지 않는다. `POST /v7/ratings`는 Authorization Header만으로
/// 누구의 평점인지 정해진다. 등록 result의 Rating 객체는 현재 세션 목록에 넣는다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._store,
    this._auth,
    this.movie,
  );

  final RatingApiService _ratingService;
  final SessionRatingStore _store;
  final AuthViewModel _auth;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// Snackbar로 보여줄 실패 문구. 세션 만료일 때는 비워 둔다. (로그인 화면이 안내한다)
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return; // 연속 탭 방지
    final sessionVersion = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(
          // 5주차 TmdbMovieDto.id. 영화 배열 index가 아니다. memberId는 body에 넣지 않는다.
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      // 로그아웃·회원 전환 뒤 늦게 도착한 이전 세션의 응답은 반영하지 않는다.
      if (sessionVersion != _auth.sessionVersion) return;
      _store.add(rating);
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed || sessionVersion != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        // AUTH401_2/3/4: 세션을 정리하면 Router가 /login으로 보낸다.
        await _auth.expireSession();
      } else {
        // 409 중복 등록 · 400 별점 범위 · 네트워크 실패 → 안내만 하고 로그인 상태를 유지한다.
        submitMessage = ratingErrorMessage(error);
      }
    } on StateError {
      // 성공 응답인데 result의 Rating 객체가 없는 것처럼 예상하지 못한 응답
      if (_disposed || sessionVersion != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 잠시 후 다시 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
