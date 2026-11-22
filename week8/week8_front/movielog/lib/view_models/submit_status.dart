/// [7주차] 쓰기 요청(회원가입·평점 등록)의 진행 상태.
///
/// Dart에서는 클래스 안에 enum을 선언할 수 없으므로 파일로 분리해
/// SignUpViewModel과 MovieDetailViewModel이 함께 쓴다.
enum SubmitStatus { idle, submitting, success, error }
