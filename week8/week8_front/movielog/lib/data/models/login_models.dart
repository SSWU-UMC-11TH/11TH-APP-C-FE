/// [8주차] 로그인 요청 body (`POST /v7/auth/login`).
///
/// 비밀번호는 요청 body로만 보내고 저장하거나 로그로 남기지 않는다.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
      };
}

/// [8주차] 로그인 성공 응답의 `result`.
///
/// memberId는 없다. 문서에 없는 field나 JWT claim을 추정하지 않는다.
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
