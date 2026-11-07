import 'package:movielog/models/movie.dart';

const mockMovies = [
  Movie(
    id: '1',
    title: '별빛 아래 우리',
    genre: '로맨스',
    year: 2024,
    posterAsset: 'assets/images/posters/poster1.png',
    rating: 4.8,
    runtime: 120,
  ),
  Movie(
    id: '2',
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster2.jpg',
    rating: 4.2,
    runtime: 110,
  ),
  Movie(
    id: '3',
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster3.jpg',
    rating: 4.9,
    runtime: 98,
  ),
  Movie(
    id: '4',
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster4.jpg',
    rating: 3.8,
    runtime: 105,
  ),
  Movie(
    id: '5',
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster5.jpg',
    rating: 4.5,
    runtime: 102,
  ),
  Movie(
    id: '6',
    title: '도시의 리듬',
    genre: '다큐멘터리',
    year: 2023,
    posterAsset: 'assets/images/posters/poster6.png',
    rating: 4.1,
    runtime: 98,
  ),
];

Movie findMovieById(String id) => mockMovies.firstWhere((m) => m.id == id);
