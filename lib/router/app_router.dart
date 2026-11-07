import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  // root Navigator를 가리키는 키. 하단 탭(ShellRoute) 위에 화면을 띄울 때 씁니다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(
            context.read<MemberCheckService>(),
          ),
          child: const RegisterScreen(),
        ),
      ),
      // 상세 화면은 NavigationBar 없이 탭 화면 위에 push로 쌓입니다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) => MovieDetailScreen(
          movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
          // 목록에서 넘긴 DTO (URL로 바로 들어오면 null → id로 다시 조회)
          initialMovie: state.extra is TmdbMovieDto
              ? state.extra as TmdbMovieDto
              : null,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          // 화면(페이지)마다 ViewModel을 하나씩 만들고,
          // 공용 TmdbMovieService는 최상단 MultiProvider에서 꺼내 씁니다.
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
              create: (context) => MovieHomeViewModel(
                context.read<TmdbMovieService>(),
              )..loadPopular(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieListViewModel>(
              create: (context) => MovieListViewModel(
                context.read<TmdbMovieService>(),
              )..loadInitial(),
              child: const MovieListScreen(),
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyPageScreen(),
            routes: [
              GoRoute(
                path: 'ratings', // 최종 경로: /my/ratings
                // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ChangeNotifierProvider<MyRatingsViewModel>(
                  create: (context) => MyRatingsViewModel(
                    context.read<RatingApiService>(),
                    context.read<TmdbMovieService>(),
                    sampleMemberId, // 6주차는 학습용 memberId 1
                  )..load(),
                  child: const MyRatingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;
    return 0;
  }
}
