import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/service/sign_up_service.dart';
import 'package:movielog/view_models/submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;

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

  // 제출
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText; // 400 중 비밀번호 오류
  String? snackbarMessage; // 그 외 400, 409 등

  bool _disposed = false;

  bool get canCheckNickname =>
      _currentNickname.isNotEmpty && nicknameCheckStatus != CheckStatus.checking;

  bool get canCheckEmail =>
      _currentEmail.isNotEmpty && emailCheckStatus != CheckStatus.checking;

  /// 닉네임·이메일 중복 확인이 모두 통과해야 가입 가능
  bool get checksPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  // ---------- 닉네임 ----------
  void onNicknameChanged(String value) {
    _currentNickname = value.trim();
    _nicknameVersion++; // 기다리던 이전 응답 무효화
    nicknameCheckStatus = CheckStatus.idle; // 이전 결과 무효화
    nicknameErrorText = null;
    _clearSubmitError();
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
        nicknameCheckStatus = CheckStatus.duplicated;
        nicknameErrorText = '이미 사용 중인 닉네임입니다.';
      }
    } catch (_) {
      if (_disposed || version != _nicknameVersion) return;
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
    _clearSubmitError();
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

  // ---------- 비밀번호 ----------
  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    _notify();
  }

  // ---------- 제출 ----------
  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) return; // 중복 탭 방지
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    _notify();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      // 비밀번호 오류로 확인된 400만 입력칸에, 나머지는 Snackbar로
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    } catch (_) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
    _notify();
  }

  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) {
      submitStatus = SubmitStatus.idle;
      snackbarMessage = null;
    }
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