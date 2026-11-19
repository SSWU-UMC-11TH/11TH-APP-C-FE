import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 선택한 장르처럼 단순하고 중요하지 않은 값만 저장합니다.
/// (JWT·비밀번호 같은 민감한 값은 flutter_secure_storage에 저장해야 합니다.)
///
/// 5주차부터는 장르 이름 대신 TMDB 장르 id를 저장합니다. null = "전체".
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedGenreIdKey = 'selected_genre_id';

  final SharedPreferencesAsync _preferences;

  Future<int?> readGenreId() {
    return _preferences.getInt(_selectedGenreIdKey);
  }

  Future<void> saveGenreId(int? genreId) async {
    if (genreId == null) {
      await _preferences.remove(_selectedGenreIdKey);
    } else {
      await _preferences.setInt(_selectedGenreIdKey, genreId);
    }
  }
}
