import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/service/auth_api_service.dart';
import 'package:movielog/data/service/member_api_service.dart';
import 'package:movielog/data/service/rating_api_service.dart';
import 'package:movielog/data/service/sign_up_service.dart';
import 'package:movielog/data/service/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    final publicClient = createMovieLogClient(); // 토큰 Interceptor 없음
    final authClient = createAuthMovieLogClient(tokenStorage); // 보호 요청용

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        // TMDB Client는 MovieLog JWT와 완전히 분리
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(publicClient)),
        Provider<MemberApiService>(
            create: (_) => MemberApiService(authClient)),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<MyRatingsViewModel>(
          create: (context) => MyRatingsViewModel(
            context.read<RatingApiService>(),
            context.read<TmdbMovieService>(),
            context.read<AuthViewModel>(),
          ),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(auth); // 앱에서 한 번만 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.restoreSession();
    });
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
      theme: AppTheme.light, // 기존 테마 코드 그대로
      routerConfig: _router,
    );
  }
}