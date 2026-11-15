import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';

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
        builder: (context, state) => MovieDetailScreen(
          // Route path의 ':movieId'와 Key 이름이 같아야 한다.
          movieId: state.pathParameters['movieId'],
        ),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => MovieListScreen(
                  // [Challenge] 선택한 장르를 Query Parameter로 표현한다.
                  //   /movies?genre=드라마,SF
                  selectedGenres: parseGenres(
                    state.uri.queryParameters['genre'],
                  ),
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

  /// 'genre' Query Parameter("드라마,SF") → {'드라마', 'SF'}
  static Set<String> parseGenres(String? raw) {
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((genre) => genre.isNotEmpty).toSet();
  }

  /// 선택한 장르 → '/movies?genre=드라마,SF' (선택이 없으면 '/movies')
  static String movieListLocation(Set<String> selectedGenres) {
    if (selectedGenres.isEmpty) return '/movies';
    return Uri(
      path: '/movies',
      queryParameters: {'genre': selectedGenres.join(',')},
    ).toString();
  }
}