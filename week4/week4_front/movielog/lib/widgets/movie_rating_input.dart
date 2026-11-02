import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_theme.dart';

/// 별점을 "어떻게 입력할지"만 담당한다.
/// 실제 별점 값은 부모 Widget이 State로 들고, onChanged로 전달받는다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      glow: false,
      unratedColor: AppColors.starOff,
      itemBuilder: (context, index) {
        return const Icon(
          Icons.star,
          color: AppColors.primary,
        );
      },
      onRatingUpdate: onChanged,
    );
  }
}