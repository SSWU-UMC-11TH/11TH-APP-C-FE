import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService();

  group('FakeMovieService.fetchMovies', () {
    test('success: 영화 목록을 반환한다', () async {
      final result = await service.fetchMovies();

      expect(result, isNotEmpty);
    });

    test('empty: 빈 목록을 반환한다', () async {
      final result = await service.fetchMovies(mode: MovieLoadMode.empty);

      expect(result, isEmpty);
    });

    test('failure: MovieLoadException으로 완료된다', () async {
      await expectLater(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });

    test('응답이 제한 시간보다 늦으면 TimeoutException이 발생한다', () async {
      await expectLater(
        service.fetchMovies().timeout(const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}