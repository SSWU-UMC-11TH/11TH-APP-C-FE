import 'package:flutter/foundation.dart';

import '../data/genre_preference.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면 전용 ViewModel.
/// 장르 목록, 선택된 장르, Discover 최대 30개 결과와 화면 상태를 관리합니다.
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {GenrePreference? genrePreference})
      : _genrePreference = genrePreference ?? GenrePreference();

  static const maxMovies = 30;

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// null이면 "전체" (with_genres를 보내지 않음)
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// 장르를 빠르게 바꿨을 때 늦게 도착한 이전 응답을 버리기 위한 요청 번호.
  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;

  bool _isStale(int version) => _disposed || version != _requestVersion;

  /// Discover API를 page 1부터 필요한 만큼 요청해 TMDB id 기준 중복 없는 최대 30개를 만듭니다.
  /// 한 페이지 개수(20개)를 코드에 하드코딩하지 않고, 30개가 되거나 페이지가 끝날 때까지 반복합니다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        // 같은 id가 다시 와도 Map key가 같아서 하나만 남습니다.
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovies).toList();
  }

  /// 화면 진입 시 1회: 저장된 장르 → 장르 목록 + 영화 목록을 함께 불러옵니다.
  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final savedGenreId = await _genrePreference.readGenreId();
      if (_isStale(version)) return;

      final results = await Future.wait([
        _service.fetchGenres(),
        fetchUpToThirtyMovies(genreId: savedGenreId),
      ]);
      if (_isStale(version)) return;

      genres = results[0] as List<TmdbGenreDto>;
      var loadedMovies = results[1] as List<TmdbMovieDto>;
      selectedGenreId = savedGenreId;

      // 저장된 장르가 지금 TMDB 장르 목록에 없다면 "전체"로 다시 불러옵니다.
      final savedGenreExists =
          savedGenreId == null || genres.any((g) => g.id == savedGenreId);
      if (!savedGenreExists) {
        selectedGenreId = null;
        await _genrePreference.saveGenreId(null);
        loadedMovies = await fetchUpToThirtyMovies();
        if (_isStale(version)) return;
      }

      _applyMovies(loadedMovies);
    } catch (error) {
      if (_isStale(version)) return;
      debugPrint('[MovieListViewModel] 초기 로드 실패: $error');
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// 장르 Chip 선택 → with_genres로 page 1부터 다시 조회합니다. (로컬 where 필터 X)
  Future<void> selectGenre(int? genreId) async {
    // Required 7: 요청 중에는 장르를 바꾸지 않습니다.
    if (isLoading) return;
    if (genreId == selectedGenreId && status == MovieListLoadStatus.success) {
      return;
    }

    selectedGenreId = genreId;
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    // 마지막 선택 장르 저장(4주차 기능 유지). 저장을 기다리지 않고 바로 조회합니다.
    _saveSelectedGenre(genreId);

    try {
      final result = await fetchUpToThirtyMovies(genreId: genreId);
      if (_isStale(version)) return;
      _applyMovies(result);
    } catch (error) {
      if (_isStale(version)) return;
      debugPrint('[MovieListViewModel] 장르 영화 로드 실패: $error');
      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// Error 화면의 "다시 시도": 장르 목록이 없으면 처음부터, 있으면 같은 장르로 재요청합니다.
  Future<void> retry() {
    if (genres.isEmpty) return loadInitial();
    return selectGenre(selectedGenreId);
  }

  /// 장르 저장이 실패해도 목록 조회에는 영향이 없도록 여기서 오류를 처리합니다.
  Future<void> _saveSelectedGenre(int? genreId) async {
    try {
      await _genrePreference.saveGenreId(genreId);
    } catch (error) {
      debugPrint('[MovieListViewModel] 장르 저장 실패: $error');
    }
  }

  void _applyMovies(List<TmdbMovieDto> result) {
    movies = result;
    status = result.isEmpty
        ? MovieListLoadStatus.empty
        : MovieListLoadStatus.success;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
