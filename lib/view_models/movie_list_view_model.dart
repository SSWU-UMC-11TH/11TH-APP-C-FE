import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import '../data/service/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// 결과가 30개가 되거나 더 이상 페이지가 없을 때까지 요청 (id로 중복 제거)
  Future<List<TmdbMovieDto>> _fetchUpToThirty({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(30).toList();
  }

  Future<void> _load() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      if (genres.isEmpty) {
        genres = await _service.fetchGenres();
      }
      final result = await _fetchUpToThirty(genreId: selectedGenreId);

      if (_disposed || version != _requestVersion) return;
      movies = result;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    notifyListeners();
  }

  Future<void> loadInitial() => _load();

  /// 현재 선택된 장르를 유지한 채 page 1부터 다시 요청
  Future<void> retry() => _load();

  /// null이면 "전체" (with_genres를 보내지 않음)
  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return; // 요청 중에는 장르 변경 불가
    if (genreId == selectedGenreId) return;
    selectedGenreId = genreId;
    await _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}