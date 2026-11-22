import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_rating_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';

/// [8주차] 인증 상태와 가려는 경로만 보고 보낼 곳을 정한다.
///
/// 상태만 읽고 판단한다. API 호출 같은 비동기 작업은 하지 않는다.
/// null을 반환하면 가려던 경로로 그대로 간다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired =>
      atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating =>
      atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보낸다.
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  /// [6주차] root Navigator를 가리키는 키. 클래스에서 한 번만 선언한다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  /// [8주차] redirect가 인증 상태를 읽어야 하므로 `static final router` 대신
  /// AuthViewModel 인스턴스를 받아 Router를 만든다. (앱에서 한 번만 호출한다)
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      // GoRouter 전체가 사용할 root Navigator로 등록한다.
      navigatorKey: rootNavigatorKey,
      // 인증 상태가 바뀌면 redirect를 다시 실행한다.
      // 이 연결이 없으면 redirect는 사용자가 이동할 때만 호출된다.
      refreshListenable: authViewModel,
      redirect: (context, state) {
        return authRedirect(authViewModel.status, state.uri.path);
      },
      routes: [
        GoRoute(
          path: '/start', // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
          builder: (context, state) {
            final auth = context.watch<AuthViewModel>();
            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login', // [8주차] 새로 추가한 로그인 Route
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          // [6주차] 회원가입 화면 전용 ViewModel. Service는 앱 최상단에서 가져온다.
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
              initialMovie:
                  extra is TmdbMovieDto && extra.id == id ? extra : null,
            );
          },
        ),

        // [3주차 Challenge] 탭마다 독립 Navigator를 두어 탭별 상태를 보존한다.
        // [8주차] 세 탭을 감싸는 MainScreen이 처음 열릴 때 내 정보를 한 번 불러온다.
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
                      // [8주차] 7주차까지 쓰던 memberId 대신 토큰 기반 Service를 사용한다.
                      // 목록은 현재 세션에서 등록한 평점(SessionRatingStore)이다.
                      builder: (context, state) =>
                          ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          context.read<SessionRatingStore>(),
                          context.read<AuthViewModel>(),
                        )..load(),
                        child: const MyRatingsScreen(),
                      ),
                    ),
                    // [8주차] 프로필 수정. 최종 경로: /my/profile/edit
                    GoRoute(
                      path: 'profile/edit',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        // 내 정보가 아직 없으면 수정 화면 대신 로딩·재시도를 보여준다.
                        if (auth.member == null) {
                          return Scaffold(
                            appBar: AppBar(
                              centerTitle: true,
                              title: const Text(
                                '프로필 수정',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? MovieLogButton(
                                      label: '다시 시도',
                                      onPressed: () =>
                                          auth.loadMember(force: true),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        // 프로필 수정 화면에서만 쓰는 ViewModel이므로 Route에서 연결한다.
                        return ChangeNotifierProvider<EditProfileViewModel>(
                          create: (context) => EditProfileViewModel(
                            context.read<MemberApiService>(),
                            auth,
                          ),
                          child: const EditProfileScreen(),
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
}
