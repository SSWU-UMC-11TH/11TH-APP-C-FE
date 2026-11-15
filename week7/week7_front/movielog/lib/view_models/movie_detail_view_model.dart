import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

/// [7주차] 영화 상세 화면 전용 ViewModel.
///
/// 현재 화면의 영화 DTO와 평점 "등록" 상태만 관리한다.
/// 조회·수정·삭제는 마이페이지의 '내가 등록한 평점'(MyRatingsViewModel)에서 한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);

  final RatingApiService _ratingService;

  /// 학습용 현재 회원. 로그인 인증은 아니다.
  /// 6주차 고정 memberId 1을 새 회원의 ID처럼 쓰지 않는다.
  final int? memberId;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  /// 회원가입 결과의 memberId가 있어야 평점을 등록할 수 있다.
  bool get canRate => memberId != null;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return; // 연속 탭 방지
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          // 5주차 TmdbMovieDto.id. 영화 배열 index가 아니다.
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      // 400 별점 범위 / 404 없는 유저 / 409 중복 등록 → 서버 message 그대로
      submitMessage = writeErrorMessage(error);
    } on StateError {
      // 201이 아닌 2xx처럼 예상하지 못한 응답
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 내가 등록한 평점에서 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
