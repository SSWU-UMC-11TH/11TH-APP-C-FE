import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';

void main() {
  testWidgets('시작 화면에 아이콘, 제목, 버튼이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.textContaining('영화의 순간을'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}