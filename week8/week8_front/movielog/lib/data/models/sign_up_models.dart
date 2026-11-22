/// [7주차] 회원가입 성공 응답의 `result` payload.
///
/// 응답 전체는 `CommonResponse<SignUpResult>`로 파싱하고,
/// 이 클래스는 그 안의 `result`만 표현한다.
class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  /// [8주차] v7 보호 API는 memberId를 쓰지 않는다. 값이 없어도 가입 성공으로 처리한다.
  final int? memberId;
  final String? email;
  final String? nickname;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num?)?.toInt(),
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
    );
  }
}
