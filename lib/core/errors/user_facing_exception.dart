/// 사용자에게 그대로 보여줄 수 있는 문구를 담은 예외.
/// Dialog는 이 예외를 잡으면 [message]를 오류 문구로 표시하고 입력을 유지합니다.
class UserFacingException implements Exception {
  const UserFacingException(this.message);

  final String message;

  @override
  String toString() => message;
}
