import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 상세 화면은 Shell 바깥(최상위)에 둔다.
      // → 어느 탭에서 push해도 전체 화면으로 열리고, pop 하면 원래 탭으로 돌아온다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final extra = state.extra;
          return MovieDetailScreen(
            // Route path의 ':movieId'와 Key 이름이 같아야 한다. (TMDB id)
            movieId: state.pathParameters['movieId'],
            movie: extra is TmdbMovieDto ? extra : null,
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
