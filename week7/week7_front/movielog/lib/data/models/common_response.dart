/// [7주차] v6 공통 응답 형식.
///
/// `isSuccess`, `code`, `message`, `result` 네 필드로 성공 여부·처리 결과 code·
/// 사용자 안내 message·실제 데이터를 함께 전달한다.
/// `result`는 API마다 담기는 값이 다르므로 제네릭 `T`로 표현하고,
/// 값이 없거나 실패 응답이면 null이다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }
}
