import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/sign_up_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/screens/homeScreen.dart';
import 'package:movielog/screens/movieDetailScreen.dart';
import 'package:movielog/screens/movieListScreen.dart';
import 'package:movielog/screens/myRatingsScreen.dart';
import 'package:movielog/screens/profileScreen.dart';
import 'package:movielog/screens/signupScreen.dart';
import 'package:movielog/screens/startScreen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/main_shell.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (c, s) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (c, s) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),

      // 탭 바가 없는 상세 화면
      GoRoute(
        path: '/movies/:movieId',
        builder: (c, s) {
          final movieId = int.tryParse(s.pathParameters['movieId'] ?? '') ?? 0;
          final movie = s.extra is TmdbMovieDto ? s.extra as TmdbMovieDto : null;
          return ChangeNotifierProvider<MovieDetailViewModel>(
            create: (context) => MovieDetailViewModel(
              context.read<RatingApiService>(),
              context.read<LearningMemberSession>().memberId,
              movieId,
            ),
            child: MovieDetailScreen(movieId: movieId, movie: movie),
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (c, s) => ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (c, s) => ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (c, s) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // /my/ratings
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (c, s) {
                      // 6주차 sampleMemberId 대신 가입 결과의 memberId 사용
                      final id = c.read<LearningMemberSession>().memberId;
                      if (id == null) {
                        return Scaffold(
                          appBar: AppBar(
                              centerTitle: true, title: const Text('내가 등록한 평점')),
                          body: const Center(
                              child: Text('학습용 회원가입이 필요합니다.')),
                        );
                      }
                      return ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          id,
                        )..load(),
                        child: const MyRatingsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}