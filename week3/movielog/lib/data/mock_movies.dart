import '../models/movie.dart';

/// 홈·목록·상세가 모두 이 Mock Data 하나만 읽는다.
const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/movie_1.png',
    rating: 4.5,
    ratingCount: 1245,
    runtime: 124,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 '
        '우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 '
        '서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 '
        '따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, '
        '별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 '
        '서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 '
        '장벽들은 그들의 관계를 시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 '
        '있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 '
        '올 겨울 최고의 로맨스 영화.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/movie_2.png',
    rating: 4.2,
    ratingCount: 892,
    runtime: 132,
    tags: ['SF', '우주', '미스터리'],
    synopsis: '관측 가능한 우주의 경계로 향한 탐사선. 교신이 끊긴 지 7년, '
        '마지막 승무원이 지구로 보낸 한 통의 메시지가 도착합니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/movie_3.png',
    rating: 4.9,
    ratingCount: 2310,
    runtime: 98,
    tags: ['애니메이션', '가족', '모험'],
    synopsis: '잃어버린 기억이 나무가 되어 자라는 숲. 숲의 끝에서 자신의 이름을 '
        '찾으려는 아이와 작은 정령의 여정을 그립니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/movie_4.png',
    rating: 3.8,
    ratingCount: 640,
    runtime: 117,
    tags: ['스릴러', '범죄', '긴장감'],
    synopsis: '비 내리는 골목에서 사라진 한 사람. 유일한 목격자는 그날 밤을 '
        '기억하지 못합니다.',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/movie_5.png',
    rating: 4.5,
    ratingCount: 1530,
    runtime: 109,
    tags: ['로맨스', '일상', '잔잔한'],
    synopsis: '매일 같은 시간, 같은 자리에 앉는 두 사람. 작은 카페에서 시작된 '
        '느리고 다정한 봄의 이야기입니다.',
  ),
  Movie(
    id: 6,
    title: '도시의 선',
    genre: '다큐멘터리',
    year: 2023,
    posterAsset: 'assets/images/movie_6.png',
    rating: 4.1,
    ratingCount: 410,
    runtime: 92,
    tags: ['다큐멘터리', '건축', '도시'],
    synopsis: '콘크리트와 빛이 만든 도시의 선을 따라, 건축가들이 남긴 생각을 '
        '기록한 다큐멘터리입니다.',
  ),
  Movie(
    id: 7,
    title: '스파이 코드',
    genre: '코미디',
    year: 2023,
    posterAsset: 'assets/images/movie_7.png',
    rating: 4.6,
    ratingCount: 1980,
    runtime: 105,
    tags: ['코미디', '액션', '유쾌한'],
    synopsis: '암호를 한 번도 제대로 풀어 본 적 없는 요원이 세계를 구해야 하는 '
        '단 하루의 임무를 맡습니다.',
  ),
  Movie(
    id: 8,
    title: '비 오는 날의 마법',
    genre: '판타지',
    year: 2022,
    posterAsset: 'assets/images/movie_8.png',
    rating: 4.4,
    ratingCount: 1120,
    runtime: 113,
    tags: ['판타지', '성장', '신비로운'],
    synopsis: '비가 오는 날에만 열리는 골목의 작은 문. 그 너머에서 만난 '
        '마법사와 소녀의 비밀스러운 계절.',
  ),
];

/// 장르 필터에 보여줄 장르 목록 (Figma 시안 순서)
const List<String> genres = [
  '드라마',
  'SF',
  '애니메이션',
  '스릴러',
  '로맨스',
  '코미디',
  '판타지',
  '다큐멘터리',
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

/// 선택된 장르가 없으면 전체 목록을 돌려준다.
List<Movie> filterMoviesByGenres(Set<String> selectedGenres) {
  if (selectedGenres.isEmpty) return movies;
  return movies
      .where((movie) => selectedGenres.contains(movie.genre))
      .toList();
}