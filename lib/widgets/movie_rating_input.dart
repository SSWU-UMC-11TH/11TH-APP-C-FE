import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 서버 연동 모드(v6) 별점 입력: 1~5 정수만 선택할 수 있습니다.
/// RatingBar는 값을 double로 돌려주므로 1.0, 2.0처럼 정수를 나타내는 double이 전달됩니다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  /// false면 탭을 무시합니다. (저장 중)
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false, // 반 점을 조용히 toInt()로 바꾸지 않고 처음부터 막습니다.
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 40,
      itemBuilder: (context, index) =>
          const Icon(Icons.star, color: AppColors.primary),
      onRatingUpdate: onChanged,
    );
  }
}
