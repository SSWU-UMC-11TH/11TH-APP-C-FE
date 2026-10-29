class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.description,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String description;
}

const genres = ['드라마', 'SF', '애니메이션', '스릴러'];

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    description: '별이 쏟아지는 밤, 서로 다른 길을 걷던 두 사람이 다시 만나 잊고 있던 약속을 떠올리는 이야기.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    description: '우주의 끝에서 들려오는 신호를 쫓는 탐사대가 인류의 기원과 마주하는 SF 대서사.',
  ),
  Movie(
    id: 3,
    title: '심연을 걷는 자',
    genre: 'SF',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    description: '깊은 바다 아래 잠든 도시를 탐험하는 잠수사의 고독한 여정.',
  ),
  Movie(
    id: 4,
    title: '속삭이는 숲',
    genre: '애니메이션',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    description: '말하는 나무들이 사는 숲에서 길을 잃은 소녀가 친구들을 만나 집으로 돌아가는 모험.',
  ),
  Movie(
    id: 5,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    description: '매주 같은 카페에서 마주치는 낯선 사람들의 네 번째 오후를 그린 잔잔한 드라마.',
  ),
  Movie(
    id: 6,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    description: '도시의 밤마다 나타나는 그림자의 정체를 쫓는 형사의 긴장감 넘치는 추적.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
