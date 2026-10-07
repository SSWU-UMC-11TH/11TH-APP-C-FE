// Mission 2 - Dart 최소 문법 연습
// ignore_for_file: avoid_print

/// 영화 한 편을 표현하는 Class
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    this.rating,
  });

  final int id;
  final String title;
  final String genre;
  final double? rating; // 평점은 없을 수도 있으므로 nullable
}

/// nullable 닉네임을 안전한 기본값으로 변환
String displayName(String? nickname) {
  return nickname?.trim().isNotEmpty == true ? nickname!.trim() : '이름 없음';
}

void main() {
  // List<Movie> 에 영화 3개 담기
  final movies = <Movie>[
    const Movie(id: 1, title: '인터스텔라', genre: 'SF', rating: 4.8),
    const Movie(id: 2, title: '너의 이름은', genre: '애니메이션', rating: 4.5),
    const Movie(id: 3, title: '기생충', genre: '드라마'), // rating 생략 → null
  ];

  // 1) for 문으로 출력
  print('--- for 문 ---');
  for (final movie in movies) {
    final ratingText = movie.rating?.toStringAsFixed(1) ?? '평점 없음';
    print('${movie.id}. ${movie.title} (${movie.genre}) · $ratingText');
  }

  // 2) map 으로 제목만 뽑기
  print('\n--- map ---');
  final titles = movies.map((movie) => movie.title).toList();
  print(titles.join(', '));

  // 3) Null Safety 확인
  print('\n--- Null Safety ---');
  print(displayName('무비러버'));
  print(displayName(null));
  print(displayName('   '));
}