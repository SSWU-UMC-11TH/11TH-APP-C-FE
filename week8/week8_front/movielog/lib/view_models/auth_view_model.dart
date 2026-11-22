import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

/// 앱 전체의 인증 상태. Router의 redirect가 이 값만 보고 화면을 정한다.
///
/// - initializing: 앱 시작 직후 저장된 토큰을 확인하는 중 (Splash)
/// - signedOut: 로그아웃 상태 (로그인·회원가입만 허용)
/// - authenticating: 로그인 요청 중
/// - signedIn: 로그인됨
/// - retryRequired: 세션 확인에 실패해 다시 시도가 필요한 상태 (Splash + 다시 시도)
enum AuthStatus { initializing, signedOut, authenticating, signedIn, retryRequired }

/// 내 정보(GET me) 로딩 상태. 인증 상태와 별개로 관리한다.
enum MemberLoadStatus { idle, loading, success, error }

/// [8주차] 로그인·세션 복원·내 정보·로그아웃을 담당하는 ViewModel.
///
/// 앱 최상단에 하나만 두고, GoRouter의 refreshListenable로도 연결한다.
/// 토큰 문자열이 저장돼 있다는 이유만으로 signedIn을 확정하지 않는다.
/// 앱 재시작은 `/members/me` 서버 검증 뒤에만 signedIn이 된다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  /// 로그인·세션 복원·세션 정리 때마다 증가한다.
  /// 이전 세션에서 늦게 도착한 응답이 새 세션을 바꾸지 못하게 비교하는 값이다.
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  /// 토큰 만료·무효로 정리됐을 때만 켜진다. (직접 로그아웃·로그인 실패에서는 켜지 않는다)
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 신규 로그인: 로그인 API 성공 → 토큰 저장 → signedIn.
  /// 내 정보는 MainScreen이 loadMember()로 불러온다. (여기서 GET me를 중복 호출하지 않는다)
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    final version = ++_sessionVersion;
    _notify();
    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // AUTH401_1은 로그인 Form의 오류다. 세션 만료 처리와 묶지 않는다.
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 앱 시작: 저장된 토큰 읽기 → GET me로 서버 검증 → signedIn.
  ///
  /// 네트워크가 잠시 끊겼다고 유효한 토큰을 지우지 않는다.
  /// '확인 실패 + 재시도'와 '토큰 무효 + 로그아웃'을 구별한다.
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();
    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final verifiedMember = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        await _clearCurrentSession(expired: true);
        return;
      }
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 내 정보를 불러와 보관한다. MainScreen이 처음 열릴 때 한 번 호출한다.
  ///
  /// 앱 재시작 시에는 restoreSession()이 이미 member를 채웠으므로 다시 호출하지 않는다.
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return; // 이미 들고 있으면 다시 호출하지 않는다.

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답은 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredCode(apiErrorCode(error))) {
        // 세션 만료: signedOut이 되어 Router가 /login으로 보낸다.
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크 실패: 로그아웃하지 않고 재시도할 수 있게 남긴다.
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체한다. GET me를 다시 호출하지 않는다.
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    notifyListeners();
  }

  /// 다른 ViewModel이 보호 요청에서 401(AUTH401_2/3/4)을 받았을 때 세션 정리를 요청하는 진입점.
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  /// 사용자가 직접 누른 로그아웃. 만료 Snackbar는 켜지 않는다.
  ///
  /// 클라이언트의 저장소·메모리 세션만 비운다. 서버에서 토큰이 즉시 폐기됐다고 보장하지 않는다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  /// 만료 안내를 한 번 보여준 뒤 끈다. 같은 Snackbar가 반복되지 않게 한다.
  void consumeSessionExpired() {
    sessionExpired = false;
  }

  /// 세션 버전 증가 → 메모리의 내 정보 초기화 → signedOut 전환 → 저장된 토큰 삭제.
  ///
  /// 화면 이동은 직접 하지 않는다. 상태가 바뀌면 Router가 /login으로 보낸다.
  /// 동시에 여러 401이 와도 정리 중에는 다시 실행하지 않는다.
  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제한다. 정리 중 새 로그인은 막는다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장 실패여도 삭제는 시도한다.
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
