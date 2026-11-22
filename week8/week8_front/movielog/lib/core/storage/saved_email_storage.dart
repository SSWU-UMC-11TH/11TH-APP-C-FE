import 'package:shared_preferences/shared_preferences.dart';

/// [8주차 Challenge] 로그인 화면의 "이메일 저장".
///
/// shared_preferences는 평문 저장소이므로 비민감한 이메일만 둔다.
/// 비밀번호와 토큰은 여기에 저장하지 않는다. (토큰은 TokenStorage)
class SavedEmailStorage {
  static const _emailKey = 'movielog.saved_email';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> read() => _prefs.getString(_emailKey);

  Future<void> save(String email) => _prefs.setString(_emailKey, email.trim());

  Future<void> clear() => _prefs.remove(_emailKey);
}
