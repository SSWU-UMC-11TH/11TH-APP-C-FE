import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/service/member_api_service.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/sign_up_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/screens/editProfileScreen.dart';
import 'package:movielog/screens/homeScreen.dart';
import 'package:movielog/screens/loginScreen.dart';
import 'package:movielog/screens/movieDetailScreen.dart';
import 'package:movielog/screens/movieListScreen.dart';
import 'package:movielog/screens/myRatingsScreen.dart';
import 'package:movielog/screens/profileScreen.dart';
import 'package:movielog/screens/signupScreen.dart';
import 'package:movielog/screens/splashScreen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/main_shell.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

/// redirect 안에서는 상태만 읽고 판단합니다. 비동기 작업은 하지 않습니다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 세션 확인 중 또는 확인 실패(재시도): 스플래시 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired =>
      atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating =>
      atPublic ? null : '/login',
    // 로그인됨: 스플래시, 로그인, 회원가입은 홈으로
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authViewModel, // 상태가 바뀌면 redirect를 다시 실행
      redirect: (context, state) =>
          authRedirect(authViewModel.status, state.uri.path),
      routes: [
        GoRoute(
          path: '/start',
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
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (c, s) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) =>
                SignUpViewModel(context.read<SignUpService>()),
            child: const SignUpScreen(),
          ),
        ),

        // 탭 바가 없는 상세 화면
        GoRoute(
          path: '/movies/:movieId',
          builder: (c, s) {
            final movieId =
                int.tryParse(s.pathParameters['movieId'] ?? '') ?? 0;
            final movie =
                s.extra is TmdbMovieDto ? s.extra as TmdbMovieDto : null;
            return ChangeNotifierProvider<MovieDetailViewModel>(
              create: (context) => MovieDetailViewModel(
                context.read<RatingApiService>(),
                context.read<AuthViewModel>(),
                context.read<MyRatingsViewModel>(),
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
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (c, s) => ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/movies',
                builder: (c, s) => ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/my',
                builder: (c, s) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // /my/ratings
                    parentNavigatorKey: rootNavigatorKey, // 하단 탭을 가림
                    builder: (c, s) => const MyRatingsScreen(),
                  ),
                  GoRoute(
                    path: 'profile/edit', // /my/profile/edit
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final auth = context.watch<AuthViewModel>();
                      if (auth.member == null) {
                        return Scaffold(
                          appBar: AppBar(
                              centerTitle: true, title: const Text('프로필 수정')),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? MovieLogButton(
                                    label: '다시 시도',
                                    onPressed: () =>
                                        auth.loadMember(force: true))
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ChangeNotifierProvider<EditProfileViewModel>(
                        create: (context) => EditProfileViewModel(
                            context.read<MemberApiService>(), auth),
                        child: const EditProfileScreen(),
                      );
                    },
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}