import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [8주차 심화] iOS 재설치와 최초 설치 flag.
///
/// 일부 iOS 환경에서는 앱을 지웠다 다시 설치해도 Keychain 값이 남을 수 있다.
/// shared_preferences는 앱 삭제 때 함께 지워지므로, flag가 없으면 "새로 설치된 앱"으로 보고
/// secure storage에 남아 있던 값을 지운 뒤 flag를 기록한다.
///
/// 이 flag는 보안 인증 수단도, 완벽한 재설치 감지기도 아니다. (백업·복원 상황에 따라 달라진다)
Future<void> ensureInstallInitialized(FlutterSecureStorage secureStorage) async {
  const flagKey = 'movielog.install_initialized';
  final prefs = SharedPreferencesAsync();

  // 1. flag를 읽는다.
  final initialized = await prefs.getBool(flagKey) ?? false;
  if (initialized) return;

  // 2. flag가 없으면 secure storage에 남아 있던 정보를 모두 삭제한다.
  await secureStorage.deleteAll();

  // 3. 삭제에 성공한 뒤에만 flag를 기록한다.
  await prefs.setBool(flagKey, true);
}
