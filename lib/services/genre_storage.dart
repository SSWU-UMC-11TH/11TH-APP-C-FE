import 'package:shared_preferences/shared_preferences.dart';

class GenreStorage {
  static const _key = 'selected_genre';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> load() => _prefs.getString(_key);

  Future<void> save(String genre) => _prefs.setString(_key, genre);
}