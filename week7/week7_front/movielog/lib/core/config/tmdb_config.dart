import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env`의 Key 문자열을 이 파일에서만 다룬다.
abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
