import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/genre_chip_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_card.dart';

/// 영화 목록 화면.
///
/// 필터 상태를 이 화면이 직접 들고 있지 않고 URL의 Query Parameter
/// (`/movies?genre=드라마,SF`)에서 받아 온다. 필터를 바꾸는 것은
/// 곧 `context.go`로 URL을 바꾸는 것이다.
///
/// - 장르 Chip      : 하나만 빠르게 고를 때 (Required)
/// - 필터 BottomSheet: 여러 장르를 함께 고를 때 (Challenge)
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final Set<String> selectedGenres;

  /// Chip에 표시할 선택 상태.
  /// 없음 → null('전체'), 하나 → 그 장르, 여러 개 → 어떤 Chip도 선택 안 됨.
  String? get _chipSelection {
    if (selectedGenres.isEmpty) return null;
    if (selectedGenres.length == 1) return selectedGenres.first;
    return '';
  }

  void _applyGenres(BuildContext context, Set<String> genres) {
    context.go(AppRouter.movieListLocation(genres));
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await GenreFilterSheet.show(
      context,
      genres: genres,
      initialSelection: selectedGenres,
    );

    // 확인을 누르지 않고 닫은 경우(null)에는 기존 필터를 유지한다.
    if (result == null || !context.mounted) return;
    _applyGenres(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMovies = filterMoviesByGenres(selectedGenres);

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
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GenreChipBar(
                  genres: genres,
                  selectedGenre: _chipSelection,
                  onSelected: (genre) {
                    _applyGenres(
                      context,
                      genre == null ? <String>{} : <String>{genre},
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: '장르 필터',
                onPressed: () => _openFilterSheet(context),
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
                ? const Center(child: Text('조건에 맞는 영화가 없습니다.'))
                : _MovieGrid(movies: filteredMovies),
          ),
        ],
      ),
    );
  }
}

/// 한 줄에 2개씩 보여주는 영화 Grid (GridView.builder).
class _MovieGrid extends StatelessWidget {
  const _MovieGrid({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) => MovieCard(movie: movies[index]),
    );
  }
}