import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면 전용 ViewModel.
///
/// - Genre API로 장르 Chip 목록을 만든다.
/// - Discover API를 page 1부터 불러 TMDB id 기준 중복 없이 최대 30개를 만든다.
/// - 장르가 바뀌면 `with_genres`로 page 1부터 다시 요청한다.
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  static const int maxMovieCount = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// [Challenge] 여러 장르를 고를 수 있도록 목록으로 둔다. null이면 '전체'.
  List<int>? selectedGenreIds;

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// [Challenge] 당겨서 새로고침 중. 이때는 기존 목록을 지우지 않는다.
  bool isRefreshing = false;

  /// 요청이 진행 중이면 장르를 바꾸지 못하게 한다.
  bool get isBusy => status == MovieListLoadStatus.loading || isRefreshing;

  /// 요청을 새로 시작할 때마다 1씩 올린다.
  /// 늦게 도착한 이전 요청의 결과는 version이 달라 버려진다.
  int _requestVersion = 0;
  bool _disposed = false;

  bool _isStale(int version) => _disposed || version != _requestVersion;

  /// 결과가 30개가 되거나 더 이상 페이지가 없을 때까지 page를 늘려 요청한다.
  /// 한 페이지의 개수(20개)는 코드에 적지 않는다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        // 같은 id가 다른 페이지에 다시 나와도 Map에는 하나만 남는다.
        byId[movie.id] = movie;
        if (byId.length == maxMovieCount) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovieCount).toList();
  }

  /// 처음 진입할 때와 Error 화면에서 다시 시도할 때 호출한다.
  /// 장르 목록과 현재 선택된 장르의 영화 목록을 함께 불러온다.
  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    movies = const [];
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      genres = await _service.fetchGenres();
      final discovered = await fetchUpToThirtyMovies(
        genreIds: selectedGenreIds,
      );

      if (_isStale(version)) return;
      movies = discovered;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_isStale(version)) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    notifyListeners();
  }

  /// 장르 Chip(하나) 또는 BottomSheet(여러 개)에서 장르를 고르면 호출한다.
  /// 빈 목록·null은 '전체'이며 `with_genres`를 보내지 않는다.
  Future<void> selectGenres(List<int>? genreIds) async {
    // Discover 요청 중에는 장르를 바꾸지 않는다.
    if (isBusy) return;

    final normalized = (genreIds == null || genreIds.isEmpty)
        ? null
        : ([...genreIds]..sort());
    // 같은 조건을 다시 고르면 요청하지 않는다.
    if (listEquals(normalized, selectedGenreIds)) return;

    selectedGenreIds = normalized;
    final version = ++_requestVersion;
    // 장르가 바뀌면 기존 목록을 비우고 page 1부터 다시 불러온다.
    movies = const [];
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: normalized);
      if (_isStale(version)) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_isStale(version)) return;
      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
    }

    notifyListeners();
  }

  /// [Challenge] 당겨서 새로고침 / 재시도 Dialog의 재시도.
  ///
  /// 현재 선택된 장르를 유지한 채 page 1부터 최대 30개를 다시 만든다.
  /// 요청 중에도 기존 목록은 그대로 두고, 성공하면 최신 목록으로 교체한다.
  /// 실패하면 목록을 유지한 채 false를 돌려준다. (화면이 재시도 Dialog를 띄운다)
  Future<bool> refresh() async {
    if (isBusy) return true;

    final version = ++_requestVersion;
    isRefreshing = true;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (_isStale(version)) return true;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
      return true;
    } on DioException {
      if (_isStale(version)) return true;
      message = '영화 목록을 새로고침하지 못했어요.';
      return false;
    } finally {
      if (!_isStale(version)) {
        isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
