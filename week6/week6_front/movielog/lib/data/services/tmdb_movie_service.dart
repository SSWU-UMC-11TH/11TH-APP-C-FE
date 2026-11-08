import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../models/tmdb_movie_page.dart';

/// TMDB와 직접 통신하는 Service Layer.
///
/// HTTP 요청과 JSON → DTO 변환만 담당하고 상태를 갖지 않는다.
/// '인기 5개', '최대 30개', '선택한 장르' 같은 화면 정책은 ViewModel이 정한다.
class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// [genreIds]가 비어 있거나 null이면 `with_genres`를 보내지 않는다(전체).
  ///
  /// [Challenge] 여러 장르는 OR(`|`)로 이어 `28|12`처럼 보낸다.
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];
    return genres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// [6주차] movieId 하나로 영화 한 편을 조회한다.
  ///
  /// `GET /movie/{movie_id}`는 영화 객체를 직접 반환한다.
  /// 없는 영화(404)도 DioException으로 던진다.
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
    );
    return TmdbMovieDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// [6주차] 404만 null로 바꾸고, 그 밖의 네트워크 오류는 그대로 다시 던진다.
  Future<TmdbMovieDto?> findMovieById(int movieId) async {
    try {
      return await fetchMovieDetail(movieId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
