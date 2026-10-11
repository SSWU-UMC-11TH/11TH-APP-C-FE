import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 선택한 장르를 기기에 저장한다.
///
/// shared_preferences는 보안 저장소가 아니므로 장르처럼 단순하고
/// 중요하지 않은 값만 저장한다. JWT·비밀번호·개인정보는 저장하지 않는다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _selectedGenresKey = 'selected_genres';

  final SharedPreferencesAsync _preferences;

  /// 저장된 값이 없으면 빈 Set('전체')을 돌려준다.
  Future<Set<String>> read() async {
    final saved = await _preferences.getStringList(_selectedGenresKey);
    return {...?saved};
  }

  Future<void> save(Set<String> genres) async {
    await _preferences.setStringList(_selectedGenresKey, genres.toList());
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenresKey);
  }
}