import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

/// idle: 확인 전 또는 입력이 바뀌어 이전 결과가 무효화됨
/// checking: 요청 중 / available: 사용 가능 / duplicated: 이미 사용 중
/// error: 통신 자체가 실패 (서버의 available: false와는 다른 상태)
enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면 전용 ViewModel: 닉네임·이메일 중복 확인 상태를 관리합니다.
/// 두 입력란의 결과가 서로 영향을 주지 않도록 필드별로 상태를 따로 둡니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final MemberCheckService _service;

  final _nickname = _DuplicateCheck(
    duplicatedMessage: '이미 사용 중인 닉네임입니다.',
  );
  final _email = _DuplicateCheck(
    duplicatedMessage: '이미 가입된 이메일입니다.',
  );

  bool _disposed = false;

  // ----- 닉네임 -----
  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  bool get canCheckNickname => _nickname.canCheck;

  void onNicknameChanged(String value) => _onChanged(_nickname, value);

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, _service.checkNickname);

  // ----- 이메일 -----
  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  bool get canCheckEmail => _email.canCheck;

  void onEmailChanged(String value) => _onChanged(_email, value);

  Future<void> checkEmail(String value) =>
      _check(_email, value, _service.checkEmail);

  /// 닉네임과 이메일 모두 서버에서 "사용 가능"을 받았는지
  bool get isAllAvailable =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  // ----- 공통 로직 -----

  /// 입력값이 바뀌면 이전 결과를 무효화합니다.
  /// 단, 서버가 "중복"이라고 했던 값과 똑같으면 다시 묻지 않고 바로 에러로 되돌립니다.
  void _onChanged(_DuplicateCheck field, String value) {
    final trimmed = value.trim();
    field.currentValue = trimmed;
    field.requestVersion++; // 기다리던 이전 요청의 응답은 무시합니다.

    if (field.duplicatedValues.contains(trimmed)) {
      field.status = CheckStatus.duplicated;
      field.errorText = field.duplicatedMessage;
    } else {
      field.status = CheckStatus.idle;
      field.errorText = null;
    }
    _notify();
  }

  Future<void> _check(
    _DuplicateCheck field,
    String value,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (requested.isEmpty || !field.canCheck) return;
    field.currentValue = requested;

    final version = ++field.requestVersion;
    field.status = CheckStatus.checking;
    field.errorText = null;
    _notify();

    // 응답이 왔을 때 입력이 바뀌었거나 화면을 떠났다면 결과를 버립니다.
    bool isStale() =>
        _disposed ||
        version != field.requestVersion ||
        field.currentValue != requested;

    try {
      final available = await request(requested);
      if (isStale()) return;
      if (available) {
        field.status = CheckStatus.available;
        field.errorText = null;
      } else {
        field.status = CheckStatus.duplicated;
        field.errorText = field.duplicatedMessage;
        field.duplicatedValues.add(requested); // 중복이었던 값을 기억합니다.
      }
    } on DioException catch (error) {
      if (isStale()) return;
      debugPrint('[SignUpViewModel] 중복 확인 통신 실패: ${error.type.name}');
      field.status = CheckStatus.error;
      field.errorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } catch (error) {
      // 응답 모양이 예상과 다른 경우(파싱 오류)도 통신 실패와 같은 문구로 처리합니다.
      if (isStale()) return;
      debugPrint('[SignUpViewModel] 중복 확인 응답 처리 실패: $error');
      field.status = CheckStatus.error;
      field.errorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.requestVersion++;
    _email.requestVersion++;
    super.dispose();
  }
}

/// 입력란 하나(닉네임 또는 이메일)의 중복 확인 상태.
class _DuplicateCheck {
  _DuplicateCheck({required this.duplicatedMessage});

  final String duplicatedMessage;

  CheckStatus status = CheckStatus.idle;
  String? errorText;
  String currentValue = '';
  int requestVersion = 0;

  /// 서버가 "중복"이라고 응답했던 값들 (같은 값을 다시 입력하면 바로 에러)
  final Set<String> duplicatedValues = {};

  /// 요청 중이거나 이미 중복으로 확인된 값이면 버튼을 누를 수 없습니다.
  bool get canCheck =>
      status != CheckStatus.checking && status != CheckStatus.duplicated;
}
