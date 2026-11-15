import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_theme.dart';

/// 별점을 "어떻게 입력할지"만 담당한다.
/// 실제 별점 값은 부모 Widget이 State로 들고, onChanged로 전달받는다.
///
/// [7주차] v6 평점 score는 1~5 사이 정수다. 반 점 입력을 조용히 toInt()로 바꾸지 않고,
/// 서버 연동 모드에서는 별 한 개 단위로만 선택하게 한다.
/// RatingBar는 항상 double을 돌려주므로 값은 1.0, 2.0처럼 정수를 나타내는 double이다.
/// (Figma W7-01처럼 선택 안 된 별은 테두리 별로 그린다)
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  /// 저장 중에는 별점을 바꾸지 못하게 한다.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 40,
      glow: false,
      ratingWidget: RatingWidget(
        full: const Icon(Icons.star_rounded, color: AppColors.violet),
        half: const Icon(Icons.star_half_rounded, color: AppColors.violet),
        empty: const Icon(Icons.star_outline_rounded, color: AppColors.violet),
      ),
      onRatingUpdate: onChanged,
    );
  }
}
