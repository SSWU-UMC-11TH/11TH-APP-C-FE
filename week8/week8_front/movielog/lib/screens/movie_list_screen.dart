import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/genre_chip_bar.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/retry_dialog.dart';

/// 영화 목록 화면 (View).
///
/// [5주차] API 요청·필터·상태는 모두 [MovieListViewModel]이 가진다.
/// 이 화면은 ViewModel의 상태를 그리고, 사용자 입력을 ViewModel에 전달만 한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  /// 재시도 Dialog에서 '재시도'를 누르면 새로고침 표시와 함께 다시 요청한다.
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  /// [Challenge] 당겨서 새로고침.
  Future<void> _onRefresh() async {
    final viewModel = context.read<MovieListViewModel>();
    final succeeded = await viewModel.refresh();

    if (!succeeded && mounted) {
      // 새로고침 표시를 먼저 끝낸 뒤 Dialog를 띄운다. (목록은 그대로 유지)
      unawaited(_showRetryDialog());
    }
  }

  /// [Challenge] 요청 실패 재시도 Dialog.
  Future<void> _showRetryDialog() async {
    final shouldRetry = await RetryDialog.show(context);

    if (shouldRetry != true || !mounted) return;
    // 마지막으로 선택한 장르 그대로 page 1부터 다시 요청한다.
    unawaited(_refreshIndicatorKey.currentState?.show());
  }

  /// [Challenge] 여러 장르를 고르는 BottomSheet.
  Future<void> _openFilterSheet(MovieListViewModel viewModel) async {
    final result = await GenreFilterSheet.show(
      context,
      genres: viewModel.genres,
      initialSelection: {...?viewModel.selectedGenreIds},
    );

    // 확인을 누르지 않고 닫은 경우(null)에는 기존 필터를 유지한다.
    if (result == null || !mounted) return;
    unawaited(viewModel.selectGenres(result.toList()));
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
      // ViewModel이 notifyListeners()를 부르면 Consumer의 builder만 다시 실행된다.
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          final selectedCount = viewModel.selectedGenreIds?.length ?? 0;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GenreChipBar(
                      genres: viewModel.genres,
                      selectedGenreIds: viewModel.selectedGenreIds,
                      // Discover 요청 중에는 장르를 바꾸지 못하게 한다.
                      enabled: !viewModel.isBusy,
                      onSelected: (genre) {
                        // '전체'(null)는 with_genres 없이 요청한다.
                        viewModel.selectGenres(
                          genre == null ? null : [genre.id],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: '장르 필터',
                    onPressed: viewModel.isBusy || viewModel.genres.isEmpty
                        ? null
                        : () => _openFilterSheet(viewModel),
                    icon: Badge(
                      isLabelVisible: selectedCount > 1,
                      label: Text('$selectedCount'),
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: _buildBody(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(MovieListViewModel viewModel) {
    return switch (viewModel.status) {
      MovieListLoadStatus.idle ||
      MovieListLoadStatus.loading =>
        const MovieListLoading(),
      MovieListLoadStatus.error => MovieListError(
          message: viewModel.message,
          onRetry: () => context.read<MovieListViewModel>().loadInitial(),
        ),
      MovieListLoadStatus.empty => const MovieListEmpty(),
      // Loading 상태에서는 RefreshIndicator 자체가 없으므로 당겨도 동작하지 않는다.
      MovieListLoadStatus.success => RefreshIndicator(
          key: _refreshIndicatorKey,
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: MovieGrid(
            movies: viewModel.movies,
            genreNames: {
              for (final genre in viewModel.genres) genre.id: genre.name,
            },
          ),
        ),
    };
  }
}