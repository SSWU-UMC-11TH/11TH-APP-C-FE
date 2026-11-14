import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

/// 영화 상세 화면 전용 ViewModel: 현재 영화 DTO와 평점 "등록" 상태만 관리합니다.
/// (조회·수정·삭제는 마이페이지의 MyRatingsViewModel이 담당합니다)
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);

  final RatingApiService _ratingService;

  /// 회원가입으로 얻은 학습용 memberId. 로그인 인증이 아닙니다. (null = 가입 전)
  final int? memberId;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  bool get canRate => memberId != null;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      _notify();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return; // 중복 요청 방지

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          // 5주차 TmdbMovieDto.id를 그대로 movieId로 보냅니다.
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
      // 같은 COMMON404라도 등록은 "유저"를 가리키므로 서버 message를 그대로 씁니다.
      submitMessage = writeErrorMessage(error);
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
