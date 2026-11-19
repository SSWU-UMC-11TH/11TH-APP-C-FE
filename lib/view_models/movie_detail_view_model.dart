import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._myRatings,
    this.movieId,
  );

  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  final MyRatingsViewModel _myRatings;
  final int movieId; // TmdbMovieDto.id

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    if (_auth.status != AuthStatus.signedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인이 필요해요.';
      notifyListeners();
      return;
    }

    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      // body에는 movieId, score, comment만. memberId는 보내지 않음
      final rating = await _ratingService.createRating(
        CreateRatingRequest(movieId: movieId, score: score, comment: comment),
      );
      if (version != _auth.sessionVersion) return; // 이전 세션의 늦은 응답 무시
      _myRatings.addRating(rating);
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (version != _auth.sessionVersion) return;
      final code = apiErrorCode(error);
      submitStatus = SubmitStatus.error;
      if (isSessionExpiredCode(code)) {
        await _auth.expireSession();
        submitMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';
      } else {
        // 403·409·400은 서버 message 안내만, 로그아웃하지 않음
        submitMessage = apiErrorMessage(error) ??
            '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      }
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