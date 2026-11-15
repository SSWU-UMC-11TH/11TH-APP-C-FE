import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  /// [6주차] root Navigator를 가리키는 키. 클래스에서 한 번만 선언한다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    // GoRouter 전체가 사용할 root Navigator로 등록한다.
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        // [6주차] 회원가입 화면 전용 ViewModel. Service는 앱 최상단에서 가져온다.
        // [7주차] MemberCheckService → SignUpService
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(
            context.read<SignUpService>(),
          ),
          child: const RegisterScreen(),
        ),
      ),

      // 상세 화면은 Shell 바깥(최상위)에 둔다.
      // → 어느 탭에서 push해도 전체 화면으로 열리고, pop 하면 원래 탭으로 돌아온다.
      // [7주차] movieId는 URL 식별자로만 쓰고, 화면에 넘길 TmdbMovieDto는 state.extra에서 꺼낸다.
      // extra가 없으면(직접 접근·Deep Link) MovieDetailLoader가 TMDB에서 다시 조회한다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          // Route path의 ':movieId'와 Key 이름이 같아야 한다. (TMDB id)
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return const Scaffold(
              body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
            );
          }
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id ? extra : null,
          );
        },
      ),

      // [Challenge] 탭마다 독립 Navigator를 두어 탭별 상태를 보존한다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                // [5주차] 화면마다 ViewModel을 하나씩 만든다.
                // create는 한 번만 실행되므로 Popular 요청도 build마다 반복되지 않는다.
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) => MovieHomeViewModel(
                    context.read<TmdbMovieService>(),
                  )..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                // [5주차] 선택한 장르는 URL이 아니라 MovieListViewModel이 가진다.
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) => MovieListViewModel(
                    context.read<TmdbMovieService>(),
                  )..loadInitial(),
                  child: const MovieListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const MyPageScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // 최종 경로: /my/ratings
                    // [6주차] Shell(탭)의 Navigator가 아니라 root Navigator 위에 push해
                    // 하단 NavigationBar를 가린다.
                    parentNavigatorKey: rootNavigatorKey,
                    // [7주차] 6주차 고정 ID 대신 회원가입 결과의 memberId로 조회한다.
                    builder: (context, state) {
                      final id = context.read<LearningMemberSession>().memberId;
                      if (id == null) {
                        return Scaffold(
                          appBar: AppBar(
                            centerTitle: true,
                            title: const Text('내가 등록한 평점'),
                          ),
                          body: const Center(
                            child: Text('학습용 회원가입이 필요합니다.'),
                          ),
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
