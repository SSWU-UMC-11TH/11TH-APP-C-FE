import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import 'movie_detail_screen.dart';

/// 영화 상세 화면의 시작점.
/// extra(TmdbMovieDto)가 있으면 그대로 쓰고, 직접 접근·Deep Link처럼 extra가 없으면
/// TMDB GET /movie/{movie_id}로 다시 조회한 뒤 MovieDetailViewModel을 만듭니다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = _loadMovie();
  }

  Future<TmdbMovieDto> _loadMovie() {
    final initial = widget.initialMovie;
    if (initial != null) return Future.value(initial);
    return context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  void _retry() {
    setState(() => _movieFuture = _loadMovie());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _FallbackScaffold(child: const MovieListLoading());
        }
        final movie = snapshot.data;
        if (snapshot.hasError || movie == null) {
          return _FallbackScaffold(
            child: MovieListError(
              message: '영화 정보를 불러오지 못했어요.',
              onRetry: _retry,
            ),
          );
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            // 6주차 고정 memberId 1이 아니라 회원가입 결과를 사용합니다.
            context.read<LearningMemberSession>().memberId,
            movie,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}

class _FallbackScaffold extends StatelessWidget {
  const _FallbackScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '영화 상세', onBack: () => context.pop()),
      body: child,
    );
  }
}
