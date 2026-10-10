class Movie {
  final String id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final double rating;
  final int runtime;

  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.rating,
    required this.runtime,
  });
}