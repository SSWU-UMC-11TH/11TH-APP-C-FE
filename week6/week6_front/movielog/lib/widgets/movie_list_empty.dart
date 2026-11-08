import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [Empty] 빈 Grid 대신 안내 문구를 보여준다.
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 48,
              color: AppColors.textSub,
            ),
            SizedBox(height: 12),
            Text(
              '조건에 맞는 영화가 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              '다른 장르를 선택해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}