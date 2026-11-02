import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

/// 영화 Grid와 Loading Skeleton이 같은 배치를 쓰도록 공유하는 값.
const SliverGridDelegateWithFixedCrossAxisCount movieGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 20,
  childAspectRatio: 0.58,
);

const EdgeInsets movieGridPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

/// [Success] 한 줄에 2개씩 보여주는 영화 Grid (GridView.builder).
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 영화가 적어도 당겨서 새로고침이 되도록 항상 스크롤 가능하게 둔다.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: movieGridPadding,
      itemCount: movies.length,
      gridDelegate: movieGridDelegate,
      itemBuilder: (context, index) => MovieCard(movie: movies[index]),
    );
  }
}