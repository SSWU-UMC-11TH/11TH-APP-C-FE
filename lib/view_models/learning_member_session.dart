import 'package:flutter/foundation.dart';

/// 가입 결과의 memberId를 메모리에만 보관합니다. 인증이 아니라 학습용 식별자입니다.
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