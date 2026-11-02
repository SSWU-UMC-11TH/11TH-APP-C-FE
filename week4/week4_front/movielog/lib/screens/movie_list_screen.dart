import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../models/movie_list_initial_data.dart';
import '../router/app_router.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_theme.dart';
import '../widgets/genre_chip_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';

/// 영화 목록 화면.
///
/// [4주차] Mock Service가 돌려주는 Future 하나를 `FutureBuilder`로 관찰해
/// Loading·Error·Empty·Success 네 상태를 나눠 그린다.
///
/// 필터 상태는 3주차와 같이 URL의 Query Parameter(`/movies?genre=드라마,SF`)
/// 에서 받아 온다. 필터를 바꾸면 `context.go`로 URL을 바꾸고, 같은 값을
/// 기기에 저장해 다음 실행 때 복원한다.
///
/// - 장르 Chip      : 하나만 빠르게 고를 때
/// - 필터 BottomSheet: 여러 장르를 함께 고를 때
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    required this.selectedGenres,
    this.movieService = const FakeMovieService(),
    this.genrePreference,
  });

  final Set<String> selectedGenres;
  final FakeMovieService movieService;
  final GenrePreference? genrePreference;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  /// 이 시간 안에 응답이 없으면 Timeout 오류로 처리한다.
  static const Duration _timeLimit = Duration(seconds: 5);

  late final GenrePreference _genrePreference;

  /// `build`는 여러 이유로 다시 실행되므로 Future는 필드에 보관한다.
  /// 새 Future는 `initState`와 재시도·새로고침 시점에만 만든다.
  late Future<MovieListInitialData> _initialDataFuture;

  /// 처음 화면에 들어올 때 Mock Service가 돌려줄 결과.
  ///
  /// Empty·Error 화면을 확인할 때만 `MovieLoadMode.empty` 또는
  /// `MovieLoadMode.failure`로 바꿔 실행하고, 확인이 끝나면 success로 되돌린다.
  static const MovieLoadMode _initialLoadMode = MovieLoadMode.success;

  /// 이번 실행에서 사용자가 필터를 직접 바꿨는지 여부.
  /// 바꾸기 전까지만 저장돼 있던 장르를 대신 보여준다.
  bool _hasAppliedGenres = false;

  bool _isPullRefreshing = false;

  @override
  void initState() {
    super.initState();
    _genrePreference = widget.genrePreference ?? GenrePreference();
    _initialDataFuture = _loadInitialData(mode: _initialLoadMode);
  }

  /// 영화 목록과 저장된 장르는 서로 의존하지 않으므로 함께 시작한다.
  Future<MovieListInitialData> _loadInitialData({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    try {
      final results = await Future.wait<Object>([
        widget.movieService.fetchMovies(mode: mode).timeout(_timeLimit),
        _genrePreference.read(),
      ]);
      final savedGenres = results[1] as Set<String>;

      return MovieListInitialData(
        movies: results[0] as List<Movie>,
        // 장르 목록에서 사라진 값이 저장돼 있으면 버린다.
        savedGenres: savedGenres.where(genres.contains).toSet(),
      );
    } on MovieLoadException catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on TimeoutException catch (error) {
      debugPrint('영화 로드 시간 초과: $error');
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료');
    }
  }

  /// 재시도할 때만 새로운 Future를 만든다. (기본 mode인 success로 다시 요청)
  void _retry() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  /// [Challenge] 당겨서 새로고침.
  Future<void> _refresh() async {
    final future = _loadInitialData();

    setState(() {
      _isPullRefreshing = true;
      _initialDataFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // 오류 화면은 FutureBuilder가 그린다. 여기서는 새로고침 표시만 끝낸다.
    } finally {
      // 기다리는 동안 화면이 제거됐을 수 있으므로 mounted를 확인한다.
      if (mounted) {
        setState(() {
          _isPullRefreshing = false;
        });
      }
    }
  }

  /// 이번에 화면에 적용할 장르.
  ///
  /// 사용자가 직접 바꿨거나 URL에 장르가 있으면 URL을 따르고,
  /// 그렇지 않으면(앱을 막 다시 실행한 경우) 저장돼 있던 장르를 쓴다.
  Set<String> _effectiveGenres(MovieListInitialData? data) {
    if (_hasAppliedGenres || widget.selectedGenres.isNotEmpty) {
      return widget.selectedGenres;
    }
    return data?.savedGenres ?? const <String>{};
  }

  /// Chip에 표시할 선택 상태.
  /// 없음 → null('전체'), 하나 → 그 장르, 여러 개 → 어떤 Chip도 선택 안 됨.
  String? _chipSelection(Set<String> selection) {
    if (selection.isEmpty) return null;
    if (selection.length == 1) return selection.first;
    return '';
  }

  Future<void> _applyGenres(Set<String> selection) async {
    setState(() {
      _hasAppliedGenres = true;
    });
    context.go(AppRouter.movieListLocation(selection));

    try {
      // await하지 않으면 저장이 끝나기 전에 앱이 종료될 수 있다.
      await _genrePreference.save(selection);
    } catch (error) {
      debugPrint('장르 저장 실패: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 장르를 저장하지 못했습니다.')),
      );
    }
  }

  Future<void> _openFilterSheet(Set<String> currentSelection) async {
    final result = await GenreFilterSheet.show(
      context,
      genres: genres,
      initialSelection: currentSelection,
    );

    // 확인을 누르지 않고 닫은 경우(null)에는 기존 필터를 유지한다.
    if (result == null || !mounted) return;
    await _applyGenres(result);
  }

  /// 내부 Exception 대신 사용자에게 보여줄 문구를 고른다.
  String _errorMessageFor(Object? error) {
    if (error is TimeoutException) {
      return '응답이 늦어지고 있습니다.';
    }
    return '영화를 불러오지 못했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: const Text(
          '영화',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<MovieListInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          // 당겨서 새로고침 중에는 기존 목록을 유지하고, 그 밖에는 Loading.
          final isWaiting =
              snapshot.connectionState == ConnectionState.waiting;
          final keepsListWhileRefreshing = _isPullRefreshing && data != null;

          if (isWaiting && !keepsListWhileRefreshing) {
            return const MovieListLoading();
          }

          // 오류를 빈 목록보다 먼저 확인해야 Error가 Empty로 보이지 않는다.
          if (snapshot.hasError) {
            return MovieListError(
              message: _errorMessageFor(snapshot.error),
              onRetry: _retry,
            );
          }

          final selectedGenres = _effectiveGenres(data);
          final filteredMovies = filterMoviesByGenres(
            selectedGenres,
            source: data?.movies ?? const <Movie>[],
          );

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GenreChipBar(
                      genres: genres,
                      selectedGenre: _chipSelection(selectedGenres),
                      onSelected: (genre) {
                        _applyGenres(
                          genre == null ? <String>{} : <String>{genre},
                        );
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: '장르 필터',
                    onPressed: () => _openFilterSheet(selectedGenres),
                    icon: Badge(
                      isLabelVisible: selectedGenres.length > 1,
                      label: Text('${selectedGenres.length}'),
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: filteredMovies.isEmpty
                    ? const MovieListEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: MovieGrid(movies: filteredMovies),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}