import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// 테스트 화면을 휴대폰 크기로 맞춘다. 기본 크기(800x600)에서는
/// 2열 카드 하나가 화면보다 길어진다.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 테스트용 TMDB 영화. 네트워크 이미지를 부르지 않도록 포스터는 null로 둔다.
TmdbMovieDto _movie(int id, String title) {
  return TmdbMovieDto(
    id: id,
    title: title,
    overview: '',
    posterPath: null,
    backdropPath: null,
    releaseDate: '2024-01-01',
    genreIds: const [],
    voteAverage: 8,
    popularity: 1,
  );
}

void main() {
  testWidgets('Loading: Skeleton을 보여준다', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_wrap(const MovieListLoading()));

    expect(find.bySemanticsLabel('영화 목록을 불러오는 중'), findsOneWidget);
  });

  testWidgets('Empty: 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListEmpty()));

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error: 다시 시도 버튼을 누르면 onRetry가 호출된다', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      _wrap(MovieListError(onRetry: () => retryCount++)),
    );

    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('Error: 전달한 안내 문구를 그대로 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(MovieListError(message: '응답이 늦어지고 있습니다.', onRetry: () {})),
    );

    expect(find.text('응답이 늦어지고 있습니다.'), findsOneWidget);
  });

  testWidgets('Success: 전달한 영화의 제목을 보여준다', (tester) async {
    _usePhoneSize(tester);

    await tester.pumpWidget(
      _wrap(MovieGrid(movies: [_movie(1, '영화 A'), _movie(2, '영화 B')])),
    );

    expect(find.text('영화 A'), findsOneWidget);
    expect(find.text('영화 B'), findsOneWidget);
  });

  testWidgets('poster_path가 null이면 placeholder를 보여준다', (tester) async {
    _usePhoneSize(tester);

    await tester.pumpWidget(_wrap(MovieGrid(movies: [_movie(1, '영화 A')])));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}