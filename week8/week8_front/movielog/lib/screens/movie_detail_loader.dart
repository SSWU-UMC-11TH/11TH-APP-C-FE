import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/session_rating_store.dart';
import 'movie_detail_screen.dart';

/// [7주차] 영화 상세 화면의 시작점.
///
/// 목록·홈에서 넘긴 `extra`가 있으면 그대로 쓰고, URL 직접 접근·Deep Link처럼
/// extra가 없으면 TMDB `GET /movie/{movie_id}`로 다시 조회한다.
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
  late final Future<TmdbMovieDto> _movieFuture;

  @override
  void initState() {
    super.initState();
    // build마다 새 Future를 만들지 않도록 initState에서 한 번만 만든다.
    _movieFuture = widget.initialMovie != null
        ? Future.value(widget.initialMovie!)
        : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('영화를 불러오지 못했습니다.')),
          );
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            // [8주차] memberId 대신 현재 세션의 평점 목록과 인증 상태를 넘긴다.
            context.read<SessionRatingStore>(),
            context.read<AuthViewModel>(),
            snapshot.data!,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
