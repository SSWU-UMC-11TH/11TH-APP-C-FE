import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/member_check_service.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/screens/homeScreen.dart';
import 'package:movielog/screens/movieDetailScreen.dart';
import 'package:movielog/screens/movieListScreen.dart';
import 'package:movielog/screens/myRatingsScreen.dart';
import 'package:movielog/screens/profileScreen.dart';
import 'package:movielog/screens/signupScreen.dart';
import 'package:movielog/screens/startScreen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/main_shell.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();

  // root Navigator 키 (탭 바를 가리는 화면용)
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (c, s) => const StartScreen()),
      GoRoute(
  path: '/register',
  builder: (c, s) => ChangeNotifierProvider<SignUpViewModel>(
    create: (context) =>
        SignUpViewModel(context.read<MemberCheckService>()),
    child: const SignUpScreen(),
  ),
),

      // 탭 바가 없는 상세 화면
      GoRoute(
        path: '/movies/:movieId',
        builder: (c, s) => MovieDetailScreen(
          movieId: int.tryParse(s.pathParameters['movieId'] ?? '') ?? 0,
          movie: s.extra is TmdbMovieDto ? s.extra as TmdbMovieDto : null,
        ),
      ),

      // 탭 바가 있는 화면 3개
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
                    path: 'ratings', // 최종 경로: /my/ratings
                    parentNavigatorKey: rootNavigatorKey, // 하단 탭을 가림
                    builder: (c, s) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        sampleMemberId,
                      )..load(),
                      child: const MyRatingsScreen(),
                    ),
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