import 'package:flutter/material.dart';

/// TMDB `poster_path`를 실제 이미지 URL로 바꿔 보여준다.
///
/// - `poster_path`는 '/abc.jpg' 같은 파일 경로만 오므로 base URL + size를 붙인다.
/// - 경로가 null이거나 이미지 로드에 실패하면 placeholder를 보여준다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String? posterPath;
  final double width;
  final double height;
  final BoxFit fit;

  static const _baseUrl = 'https://image.tmdb.org/t/p';
  static const _size = 'w500';

  String? get _imageUrl {
    if (posterPath == null || posterPath!.isEmpty) return null;
    return '$_baseUrl/$_size$posterPath';
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
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
