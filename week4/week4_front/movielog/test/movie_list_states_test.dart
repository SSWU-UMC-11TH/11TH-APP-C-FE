import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
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
    final firstTwo = movies.take(2).toList();

    await tester.pumpWidget(_wrap(MovieGrid(movies: firstTwo)));

    expect(find.text(firstTwo[0].title), findsOneWidget);
    expect(find.text(firstTwo[1].title), findsOneWidget);
  });
}