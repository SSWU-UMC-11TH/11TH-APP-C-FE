import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

/// [8주차] 현재 로그인 세션에서 등록한 평점을 메모리에 보관한다.
///
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없고, 로그인·내 정보 응답에 memberId도 없다.
/// 그래서 등록 response로 받은 Rating을 여기에 두고, 같은 세션에서 수정·삭제한다.
/// 앱을 재시작하면 비워지며, 기존 내 평점 전체 복원은 이번 주 범위가 아니다.
///
/// 로그아웃·만료·회원 전환으로 세션 버전이 바뀌면 이전 세션의 평점을 모두 지운다.
class SessionRatingStore extends ChangeNotifier {
  SessionRatingStore(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;
  final List<RatingDto> _ratings = [];

  /// 최근에 등록한 평점이 앞에 온다.
  List<RatingDto> get ratings => List.unmodifiable(_ratings);

  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings.clear();
    notifyListeners();
  }

  bool contains(int ratingId) {
    return _ratings.any((rating) => rating.ratingId == ratingId);
  }

  /// 등록 result의 Rating 객체를 추가한다.
  void add(RatingDto rating) {
    _ratings.removeWhere((item) => item.ratingId == rating.ratingId);
    _ratings.insert(0, rating);
    notifyListeners();
  }

  /// 수정 result의 Rating 객체로 같은 ratingId의 기록을 교체한다.
  void replace(RatingDto rating) {
    final index = _ratings.indexWhere(
      (item) => item.ratingId == rating.ratingId,
    );
    if (index < 0) return;
    _ratings[index] = rating;
    notifyListeners();
  }

  void remove(int ratingId) {
    final before = _ratings.length;
    _ratings.removeWhere((item) => item.ratingId == ratingId);
    if (_ratings.length != before) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
