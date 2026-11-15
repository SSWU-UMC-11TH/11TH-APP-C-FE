import 'package:flutter/foundation.dart';

/// [7주차] 학습용 현재 회원 상태.
///
/// 회원가입 결과의 memberId를 앱 최상단에 보관하고, 영화 상세·마이페이지 Route에서
/// 같은 값을 읽는다. 메모리 안에만 있으므로 앱을 재시작하면 사라진다.
///
/// memberId만 알고 있다는 사실은 인증이 아니다.
/// JWT 주차에는 memberId path를 없애고 서버가 토큰으로 현재 회원을 식별한다.
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
