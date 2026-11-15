import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

/// 중복 확인 상태. 버튼을 누를 수 있는지와 Form의 에러 상태가 모두 이 값에서 나온다.
///
/// - idle: 아직 확인하지 않았거나, 입력이 바뀌어 이전 결과가 무효화된 상태
/// - checking: 요청 진행 중
/// - available: 서버가 사용 가능하다고 응답
/// - duplicated: 서버가 이미 사용 중이라고 응답 (`available: false`)
/// - error: 통신 자체가 실패 (DioException)
enum CheckStatus { idle, checking, available, duplicated, error }

/// [6~7주차] 회원가입 화면 전용 ViewModel.
///
/// 닉네임과 이메일은 결과가 서로 영향을 주지 않도록 상태·요청 버전·현재 입력값을
/// 필드별로 따로 관리한다.
/// [7주차] 6주차 MemberCheckService를 SignUpService로 교체하고 회원가입 제출 상태를 추가했다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;
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

  // ─────────────── [7주차] 회원가입 제출 ───────────────
  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답에서 읽은 실제 ID.
  int? createdMemberId;

  /// 비밀번호 입력칸에 바로 붙일 수 있는 필드 단위 오류 (비밀번호 형식 400).
  String? passwordErrorText;

  /// 어느 입력칸에도 붙일 수 없는 화면 단위 오류 (그 밖의 400, 409 중복 등).
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  /// [Challenge] 중복으로 확인된 값은 입력을 바꾸기 전까지 다시 확인할 수 없다.
  /// [7주차] 제출 중에는 중복 확인도 다시 하지 않는다.
  bool get canCheckNickname =>
      !isSubmitting &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !isSubmitting &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  /// 현재 닉네임·이메일이 모두 사용 가능으로 확인되고, 제출 중이 아니어야 가입할 수 있다.
  /// (로컬 Form 검증은 제출 버튼을 누를 때 validate로 확인한다.)
  bool get canSubmit =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available &&
      !isSubmitting;

  /// [7주차] 이전 제출의 서버 오류를 지운다. 입력이 바뀌면 그 오류는 더 이상 현재 값의 결과가 아니다.
  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    snackbarMessage = null;
  }

  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _nicknameRequestVersion++; // 기다리던 이전 요청의 응답을 무효화한다.
    _clearSubmitError();

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
    _clearSubmitError();

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

  /// [7주차] 비밀번호를 고치면 서버가 거부했던 비밀번호 오류를 지운다.
  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    notifyListeners();
  }

  /// [7주차] 회원가입 POST.
  ///
  /// 400 중 비밀번호 형식 위반으로 확인된 경우만 passwordErrorText로,
  /// 그 밖의 400과 409(중복)는 snackbarMessage로 나눠 담는다.
  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return; // 연속 탭 방지
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      // memberId가 없는 성공 응답은 가입 완료로 표시하지 않고 계약 오류로 처리한다.
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
