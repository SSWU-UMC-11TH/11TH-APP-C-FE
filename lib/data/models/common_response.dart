import 'package:dio/dio.dart';

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

/// 오류 응답의 message. 파싱 실패로 오류 처리가 또 터지지 않게 안전하게 읽습니다.
String? extractServerMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return null;
}

/// 오류 응답의 code (COMMON400, COMMON404 등)
String? extractServerCode(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final code = data['code'];
    if (code is String) return code;
  }
  return null;
}