import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env에서 TMDB 값을 읽는 코드를 한곳에 모읍니다.
/// Token 원문은 절대 print/log로 출력하지 않습니다.
abstract final class TmdbConfig {
  static const _accessTokenKey = 'TMDB_ACCESS_TOKEN';

  static String get accessToken => dotenv.env[_accessTokenKey] ?? '';

  /// .env가 없거나 값이 비어 있으면 false. (401의 흔한 원인)
  static bool get hasAccessToken => accessToken.trim().isNotEmpty;
}
