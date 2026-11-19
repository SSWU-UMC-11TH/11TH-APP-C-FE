import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/service/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError; // 입력칸 아래 오류
  String? message; // Snackbar 오류
  bool _disposed = false;

  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  Future<bool> save(String input) async {
    if (status == EditProfileStatus.saving) return false; // 중복 탭 방지
    final version = _auth.sessionVersion;
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }

    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (_disposed ||
          version != _auth.sessionVersion ||
          _auth.status != AuthStatus.signedIn) {
        return false;
      }
      _auth.updateMember(updated);
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (_disposed || version != _auth.sessionVersion) return false;
      final code = apiErrorCode(error);
      status = EditProfileStatus.failure;
      if (isSessionExpiredCode(code)) {
        await _auth.expireSession(); // 안내와 이동은 Router와 로그인 화면이 처리
      } else if (code == 'MEMBER409_1') {
        nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값 유지
      } else if (code == 'COMMON400') {
        nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
      } else if (code == 'MEMBER404_1') {
        message = '회원 정보를 찾을 수 없어요.';
      } else {
        message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃 안 함
      }
    } catch (_) {
      if (_disposed || version != _auth.sessionVersion) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}