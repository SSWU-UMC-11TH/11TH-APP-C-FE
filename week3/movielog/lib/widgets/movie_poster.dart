import 'package:flutter/material.dart';

import '../models/movie.dart';

/// 모서리가 둥근 포스터 이미지.
/// Asset이 없을 때는 아이콘이 들어간 대체 화면을 보여준다.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.borderRadius = 12,
  });

  final Movie movie;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        movie.posterAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: colorScheme.primaryContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.movie_outlined,
              size: 36,
              color: colorScheme.onPrimaryContainer,
            ),
          );
        },
      ),
    );
  }
}