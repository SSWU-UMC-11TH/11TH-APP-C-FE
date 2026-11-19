import 'package:flutter/foundation.dart';
import '../data/service/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;

  // 닉네임
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String _currentNickname = '';
  int _nicknameVersion = 0;

  // 이메일
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String _currentEmail = '';
  int _emailVersion = 0;

  bool _disposed = false;

  bool get canCheckNickname =>
      _currentNickname.isNotEmpty && nicknameCheckStatus != CheckStatus.checking;

  bool get canCheckEmail =>
      _currentEmail.isNotEmpty && emailCheckStatus != CheckStatus.checking;

  // ---------- 닉네임 ----------
  void onNicknameChanged(String value) {
    _currentNickname = value.trim();
    _nicknameVersion++; // 기다리던 이전 응답 무효화
    nicknameCheckStatus = CheckStatus.idle; // 이전 결과 무효화
    nicknameErrorText = null;
    _notify();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || nicknameCheckStatus == CheckStatus.checking) return;
    _currentNickname = requested;

    final version = ++_nicknameVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    _notify();

    try {
      final available = await _service.checkNickname(requested);
      if (_disposed || version != _nicknameVersion) return;
      if (available) {
        nicknameCheckStatus = CheckStatus.available;
      } else {
        // 서버가 정상 응답한 "중복"
        nicknameCheckStatus = CheckStatus.duplicated;
        nicknameErrorText = '이미 사용 중인 닉네임입니다.';
      }
    } catch (_) {
      if (_disposed || version != _nicknameVersion) return;
      // 통신 자체가 실패한 경우
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    _notify();
  }

  // ---------- 이메일 ----------
  void onEmailChanged(String value) {
    _currentEmail = value.trim();
    _emailVersion++;
    emailCheckStatus = CheckStatus.idle;
    emailErrorText = null;
    _notify();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || emailCheckStatus == CheckStatus.checking) return;
    _currentEmail = requested;

    final version = ++_emailVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    _notify();

    try {
      final available = await _service.checkEmail(requested);
      if (_disposed || version != _emailVersion) return;
      if (available) {
        emailCheckStatus = CheckStatus.available;
      } else {
        emailCheckStatus = CheckStatus.duplicated;
        emailErrorText = '이미 사용 중인 이메일입니다.';
      }
    } catch (_) {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameVersion++;
    _emailVersion++;
    super.dispose();
  }
}