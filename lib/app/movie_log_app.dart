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
    // 같은 워크북 백엔드를 부르는 두 Service는 Dio 인스턴스 하나를 공유합니다.
    // (TMDB Client와는 baseUrl·헤더가 달라서 절대 합치지 않습니다.)
    final movieLogClient = createMovieLogClient();

    // 여러 화면(Route)이 함께 쓰는 객체는 MaterialApp.router 바깥 최상단에 등록합니다.
    // TmdbMovieService는 상태가 없어서 모든 ViewModel이 인스턴스 하나를 공유합니다.
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(
          create: (_) => SignUpService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
        // 회원가입으로 얻은 학습용 memberId를 회원가입·영화 상세·내 평점 화면이 함께 씁니다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
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
