import 'package:flutter/foundation.dart';

/// 회원가입으로 얻은 학습용 memberId를 앱 전체에서 공유합니다.
/// 메모리에만 있어서 앱을 재시작하면 사라집니다.
/// memberId를 알고 있다는 것은 인증이 아닙니다. (JWT 주차에서 토큰으로 바뀝니다)
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
