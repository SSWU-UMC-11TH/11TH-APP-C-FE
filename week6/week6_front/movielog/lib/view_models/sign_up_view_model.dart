import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

/// 중복 확인 상태. 버튼을 누를 수 있는지와 Form의 에러 상태가 모두 이 값에서 나온다.
///
/// - idle: 아직 확인하지 않았거나, 입력이 바뀌어 이전 결과가 무효화된 상태
/// - checking: 요청 진행 중
/// - available: 서버가 사용 가능하다고 응답
/// - duplicated: 서버가 이미 사용 중이라고 응답 (`available: false`)
/// - error: 통신 자체가 실패 (DioException)
enum CheckStatus { idle, checking, available, duplicated, error }

/// [6주차] 회원가입 화면 전용 ViewModel.
///
/// 닉네임과 이메일은 결과가 서로 영향을 주지 않도록 상태·요청 버전·현재 입력값을
/// 필드별로 따로 관리한다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final MemberCheckService _service;
  bool _disposed = false;

  // ─────────────── 닉네임 ───────────────
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;

  /// [Challenge] 마지막으로 "중복"이었던 값. 같은 값을 다시 입력하면 재요청 없이 에러로 복원한다.
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  // ─────────────── 이메일 ───────────────
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  /// [Challenge] 중복으로 확인된 값은 입력을 바꾸기 전까지 다시 확인할 수 없다.
  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  /// 닉네임·이메일 모두 사용 가능으로 확인되어야 가입하기 버튼을 누를 수 있다.
  bool get canSubmit =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _nicknameRequestVersion++; // 기다리던 이전 요청의 응답을 무효화한다.

    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      // 방금 중복이었던 값과 같으면 API를 다시 부르지 않고 즉시 에러로 돌린다.
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus =
          available ? CheckStatus.available : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } on DioException {
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }
      // 통신 실패는 "중복"과 다른 상태·문구로 보여준다.
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _nicknameRequestVersion) notifyListeners();
  }

  void onEmailChanged(String value) {
    final trimmed = value.trim();
    _currentEmail = trimmed;
    _emailRequestVersion++;

    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus =
          available ? CheckStatus.available : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _emailRequestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
