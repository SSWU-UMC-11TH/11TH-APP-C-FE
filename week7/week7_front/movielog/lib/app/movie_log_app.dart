import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [6주차] 워크북 자체 백엔드용 Dio 하나를 두 Service가 함께 쓴다.
    // TMDB Client와는 baseUrl·헤더가 다르므로 절대 하나로 합치지 않는다.
    final movieLogClient = createMovieLogClient();

    // 여러 화면(Route)이 함께 쓰는 Service는 MaterialApp.router 바깥(최상단)에 둔다.
    // 화면마다 하나씩 필요한 ViewModel은 AppRouter의 각 Route에서 만든다.
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // [7주차] 회원가입 결과의 memberId를 보관하는 학습용 현재 회원 상태.
        // 영화 상세·마이페이지 Route가 같은 값을 읽는다. (인증이 아니다)
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
        ),
        // [7주차] 6주차 MemberCheckService → SignUpService (중복 확인 + 회원가입 POST)
        Provider<SignUpService>(
          create: (_) => SignUpService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
