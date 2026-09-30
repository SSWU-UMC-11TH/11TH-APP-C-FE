class Movie {
  final String title;
  final int id;

  Movie({required this.id, required this.title});
}

String displayName(String? nickname) {
  return nickname ?? '게스트';
}

void main() {
  final movies = <Movie>[
    Movie(id: 1, title: '인터스텔라'),
    Movie(id: 2, title: '기생충'),
    Movie(id: 3, title: '센과 치히로의 행방불명'),
    ];

  for (final movie in movies) {
    print(movie.title);
    }

  print(displayName(null));
  print(displayName('yuki'));
}