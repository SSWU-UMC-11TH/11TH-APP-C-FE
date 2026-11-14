import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/view_models/submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movieId);

  final RatingApiService _ratingService;
  final int? memberId; // 학습용 현재 회원. 로그인 인증이 아닙니다.
  final int movieId; // TmdbMovieDto.id

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movieId,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error); // 400/404/409 서버 message
    } catch (_) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}