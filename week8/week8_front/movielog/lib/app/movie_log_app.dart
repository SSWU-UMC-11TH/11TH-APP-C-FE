import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/install_initializer.dart';
import '../core/storage/saved_email_storage.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_rating_store.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    const secureStorage = FlutterSecureStorage();
    final tokenStorage = SecureTokenStorage(secureStorage);

    // [8주차] 워크북 Client를 공개용과 보호용으로 나눈다.
    // TMDB Client와는 baseUrl·헤더가 다르므로 계속 하나로 합치지 않는다.
    // (TMDB 요청에 MovieLog JWT가 실리면 안 된다)
    final publicClient = createMovieLogClient(); // Interceptor 없음
    final authClient = createAuthMovieLogClient(tokenStorage); // Interceptor 등록

    // 여러 화면(Route)이 함께 쓰는 Service는 Router 바깥(최상단)에 둔다.
    // 화면마다 하나씩 필요한 ViewModel은 AppRouter의 각 Route에서 만든다.
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        // [Challenge] 로그인 화면의 "이메일 저장" (이메일만 저장)
        Provider<SavedEmailStorage>(create: (_) => SavedEmailStorage()),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client: 로그인, 회원가입·중복 확인
        Provider<AuthApiService>(
          create: (_) => AuthApiService(publicClient),
        ),
        // (6주차 MemberCheckService는 7주차에 SignUpService로 이름을 바꿨다)
        Provider<SignUpService>(
          create: (_) => SignUpService(publicClient),
        ),
        // 보호 Client (RatingApiService는 공개 조회용 publicClient도 함께 받는다)
        Provider<MemberApiService>(
          create: (_) => MemberApiService(authClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // 현재 세션에서 등록한 평점. 세션이 바뀌면 스스로 비운다.
        ChangeNotifierProvider<SessionRatingStore>(
          lazy: false,
          create: (context) => SessionRatingStore(
            context.read<AuthViewModel>(),
          ),
        ),
      ],
      child: const _MovieLogRouterApp(secureStorage: secureStorage),
    );
  }
}

/// GoRouter는 앱이 살아 있는 동안 한 번만 만든다.
///
/// build()에서 만들면 화면이 다시 그려질 때마다 Router가 새로 생겨 현재 위치가 초기화된다.
/// 그래서 StatefulWidget의 initState에서 한 번만 만들고 필드로 보관한다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp({required this.secureStorage});

  final FlutterSecureStorage secureStorage;

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    // 첫 build 이후 세션 복원을 시작한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSession(authViewModel);
    });
  }

  Future<void> _startSession(AuthViewModel authViewModel) async {
    try {
      // [심화] 최초 설치 flag 확인 → 그 다음 token을 읽고 세션 복원을 시작한다.
      await ensureInstallInitialized(widget.secureStorage);
    } catch (_) {
      // flag 확인에 실패해도 세션 복원은 진행한다. 토큰은 어차피 서버(GET me)가 검증한다.
    }
    if (mounted) await authViewModel.restoreSession();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
