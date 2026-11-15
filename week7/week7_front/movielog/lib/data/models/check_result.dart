/// [6주차] 닉네임·이메일 중복 확인 응답.
///
/// v5는 공통 Wrapper가 없으므로 응답 body(`{ "available": true }`)를
/// 그대로 fromJson에 전달한다.
class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
