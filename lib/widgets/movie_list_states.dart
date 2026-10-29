import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Loading 상태: 빈 화면 대신 진행 상태를 보여줍니다.
class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty 상태: 빈 Grid 대신 안내 문구를 보여줍니다.
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key, this.message = '조건에 맞는 영화가 없습니다.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_filter_outlined, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

/// Error 상태: 내부 오류 내용 대신 안내 문구와 다시 시도 버튼을 보여줍니다.
class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message ?? '영화를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
