import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'movie_rating_input.dart';

/// 별점을 고르는 커스텀 Dialog.
///
/// 확인을 누르면 선택한 평점(0.5 ~ 5.0)을 Navigator.pop으로 돌려주고,
/// 바깥을 눌러 닫으면 null이 돌아간다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating = 0});

  /// 이미 남긴 평점이 있으면 그 값에서 다시 선택을 시작한다.
  final double initialRating;

  static Future<double?> show(
    BuildContext context, {
    double initialRating = 0,
  }) {
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => RatingDialog(initialRating: initialRating),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;

  // [Challenge] 다시 선택할 때마다 값을 올려 별점 입력 Widget을 새로 만든다.
  int _resetCount = 0;

  bool get _hasRating => _rating > 0;

  /// [Challenge] 평점 초기화: 별을 모두 비우고 처음부터 다시 고르게 한다.
  void _reset() {
    setState(() {
      _rating = 0;
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          // Column이 화면 전체가 아니라 내용만큼만 높이를 갖게 한다.
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            MovieRatingInput(
              key: ValueKey(_resetCount),
              rating: _rating,
              onChanged: (value) {
                // 전달받은 값을 State에 저장해야 버튼 상태가 함께 갱신된다.
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 4),
            TextButton(
              // 고른 별이 없으면 다시 선택할 것도 없으므로 비활성화한다.
              onPressed: _hasRating ? _reset : null,
              child: const Text('다시 선택하기'),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // 별을 하나라도 골라야 확인할 수 있다.
                onPressed: _hasRating
                    ? () => Navigator.pop(context, _rating)
                    : null,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}