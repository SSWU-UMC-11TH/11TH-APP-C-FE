/// POST /v6/members 요청 body (Dart 객체 → JSON)
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        // 비밀번호는 입력한 문자 자체가 의미 있으므로 trim()하지 않습니다.
        'password': password,
        'nickname': nickname.trim(),
      };
}
