import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// poster_path("/abc.jpg")에 이미지 base URL과 size를 붙여 보여주는 재사용 위젯.
/// 경로가 null이거나 이미지 로드에 실패하면 placeholder를 보여줍니다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.size = 'w500',
  });

  final String? posterPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// TMDB 이미지 크기 (w185, w342, w500, w780, original ...)
  final String size;

  static const _baseUrl = 'https://image.tmdb.org/t/p';

  String? get _imageUrl {
    final path = posterPath;
    if (path == null || path.isEmpty) return null;
    return '$_baseUrl/$size$path';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    if (imageUrl == null) return _placeholder();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.card,
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.disabled,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.gray,
      ),
    );
  }
}
