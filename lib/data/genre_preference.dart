import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 선택한 장르처럼 단순하고 중요하지 않은 값만 저장합니다.
/// (JWT·비밀번호 같은 민감한 값은 flutter_secure_storage에 저장해야 합니다.)
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const allGenres = '전체';
  static const _selectedGenreKey = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(_selectedGenreKey) ?? allGenres;
  }

  Future<void> save(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}
