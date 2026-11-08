class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.rating,
    required this.ratingCount,
    required this.runtime,
    required this.tags,
    required this.synopsis,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;

  /// 평균 평점 (Mock)
  final double rating;

  /// 평점을 남긴 사람 수 (Mock)
  final int ratingCount;

  /// 상영 시간(분)
  final int runtime;
  final List<String> tags;
  final String synopsis;
}