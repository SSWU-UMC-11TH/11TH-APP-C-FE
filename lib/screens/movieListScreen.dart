import 'package:flutter/material.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/empty_view.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:provider/provider.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('영화',
            style: TextStyle(
                color: primary, fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          final genreNames = {for (final g in viewModel.genres) g.id: g.name};

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: IgnorePointer(
                  ignoring: viewModel.isLoading, // 요청 중 장르 변경 불가
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: viewModel.genres.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      // 0번은 "전체" (genreId null)
                      final int? genreId =
                          index == 0 ? null : viewModel.genres[index - 1].id;
                      final label =
                          index == 0 ? '전체' : viewModel.genres[index - 1].name;
                      final selected = viewModel.selectedGenreId == genreId;

                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        selectedColor: primary,
                        backgroundColor: const Color(0xFFE9E3F0),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => context
                            .read<MovieListViewModel>()
                            .selectGenre(genreId),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading =>
                    const LoadingView(),
                  MovieListLoadStatus.error => ErrorView(
                      onRetry: () => context.read<MovieListViewModel>().retry(),
                    ),
                  MovieListLoadStatus.empty =>
                    const EmptyView(message: '이 장르의 영화가 아직 없어요'),
                  MovieListLoadStatus.success => MovieGrid(
                      movies: viewModel.movies,
                      genreNames: genreNames,
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}