import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [8주차] 토큰을 저장·조회·삭제하는 규칙을 인증 흐름에서 분리한 추상화.
///
/// 로그인·로그아웃·Interceptor가 FlutterSecureStorage 같은 구체 구현에 직접 의존하지 않는다.
/// 비밀번호는 어디에도 저장하지 않는다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// iOS Keychain / Android Keystore 같은 OS 보안 저장 영역에 암호화해서 보관한다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
