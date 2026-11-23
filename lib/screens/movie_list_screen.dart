import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

/// View: ViewModel의 상태를 그리기만 하고, 사용자 입력은 ViewModel 메서드로 전달합니다.
/// API 호출·JSON 파싱·30개 수집 같은 로직은 이 파일에 없습니다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화'),
      // Consumer로 감싼 영역만 notifyListeners() 때 다시 그려집니다.
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              GenreChipBar(
                genres: viewModel.genres,
                selectedGenreId: viewModel.selectedGenreId,
                // 요청 중에는 Chip을 비활성화해 장르를 바꾸지 못하게 합니다.
                enabled: !viewModel.isLoading,
                onSelected: (genreId) => context
                    .read<MovieListViewModel>()
                    .selectGenre(genreId),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                      message: viewModel.message,
                      onRetry: () =>
                          context.read<MovieListViewModel>().retry(),
                    ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success =>
                    MovieGrid(movies: viewModel.movies),
                },
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
    required this.genres,
    required this.selectedGenreId,
    required this.enabled,
    required this.onSelected,
  });

  final List<TmdbGenreDto> genres;

  /// null = "전체"
  final int? selectedGenreId;
  final bool enabled;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    // 첫 Chip은 "전체"(id 없음), 나머지는 Genre API의 id/name 그대로 사용합니다.
    final items = <({int? id, String name})>[
      (id: null, name: '전체'),
      for (final genre in genres) (id: genre.id, name: genre.name),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ChoiceChip(
            label: Text(item.name),
            selected: selectedGenreId == item.id,
            // onSelected가 null이면 Chip이 비활성화됩니다.
            onSelected: enabled ? (_) => onSelected(item.id) : null,
          );
        },
      ),
    );
  }
}
