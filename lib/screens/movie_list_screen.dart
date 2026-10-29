import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/fake_movie_service.dart';
import '../data/genre_preference.dart';
import '../data/movie.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

/// 영화 목록과 저장된 장르를 함께 담는 초기 데이터.
class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
  });

  final List<Movie> movies;
  final String selectedGenre;
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _all = GenrePreference.allGenres;
  static const _filters = [_all, ...genres];

  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  late Future<MovieListInitialData> _initialFuture;

  /// Mock 결과 모드. AppBar 메뉴에서 바꿔 Empty·Error 상태를 확인합니다.
  MovieLoadMode _mode = MovieLoadMode.success;

  /// 사용자가 Chip을 누르기 전에는 null → 저장된 장르를 사용합니다.
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    // Future는 build가 아니라 initState에서 한 번만 만듭니다.
    _initialFuture = _loadInitialData();
  }

  Future<MovieListInitialData> _loadInitialData() async {
    // 서로 의존하지 않는 두 작업은 Future.wait로 함께 시작합니다.
    final results = await Future.wait([
      _movieService.fetchMovies(mode: _mode),
      _genrePreference.read(),
    ]);

    final savedGenre = results[1] as String;
    return MovieListInitialData(
      movies: results[0] as List<Movie>,
      // 저장된 값이 지금 없는 장르라면 '전체'로 되돌립니다.
      selectedGenre: _filters.contains(savedGenre) ? savedGenre : _all,
    );
  }

  /// 재시도할 때만 새로운 Future를 만들어 Loading부터 다시 시작합니다.
  void _retry() {
    setState(() {
      _initialFuture = _loadInitialData();
    });
  }

  void _changeMode(MovieLoadMode mode) {
    _mode = mode;
    _retry();
  }

  Future<void> _selectGenre(String genre) async {
    setState(() {
      _selectedGenre = genre;
    });
    await _genrePreference.save(genre);
  }

  List<Movie> _filter(List<Movie> source, String genre) {
    if (genre == _all) return source;
    return source.where((movie) => movie.genre == genre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          // 상태 확인용 메뉴는 개발(debug) 모드에서만 보여줍니다.
          if (kDebugMode)
            PopupMenuButton<MovieLoadMode>(
              tooltip: 'Mock 결과 바꾸기',
              icon: const Icon(Icons.tune),
              initialValue: _mode,
              onSelected: _changeMode,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: MovieLoadMode.success,
                  child: Text('Success'),
                ),
                PopupMenuItem(
                  value: MovieLoadMode.empty,
                  child: Text('Empty'),
                ),
                PopupMenuItem(
                  value: MovieLoadMode.failure,
                  child: Text('Error'),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<MovieListInitialData>(
        future: _initialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MovieListLoading();
          }

          // 오류를 빈 목록보다 먼저 확인합니다.
          if (snapshot.hasError) {
            return MovieListError(
              onRetry: () {
                // 재시도는 성공 모드로 다시 요청해 복구 흐름을 확인합니다.
                _changeMode(MovieLoadMode.success);
              },
            );
          }

          final data = snapshot.data;
          if (data == null) return const MovieListLoading();

          final genre = _selectedGenre ?? data.selectedGenre;
          final filtered = _filter(data.movies, genre);

          return Column(
            children: [
              GenreChipBar(
                filters: _filters,
                selected: genre,
                onSelected: _selectGenre,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const MovieListEmpty()
                    : MovieGrid(movies: filtered),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = filters[index];
          return ChoiceChip(
            label: Text(genre),
            selected: selected == genre,
            onSelected: (_) => onSelected(genre),
          );
        },
      ),
    );
  }
}
