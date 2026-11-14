import 'package:flutter/material.dart';

import '../core/errors/user_facing_exception.dart';
import '../data/models/rating_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점 + 코멘트를 입력받는 커스텀 Dialog (등록·수정 공용).
///
/// 저장 로직은 [onSubmit]으로 받아 Dialog 안에서 실행합니다.
/// - onSubmit이 예외 없이 끝나면 true를 반환하며 닫힙니다.
/// - 취소하면 onSubmit을 호출하지 않고 false를 반환합니다. (API 요청 없음)
/// - 실패하면 Dialog를 유지하고 입력을 보존한 채 오류 문구를 보여줍니다.
///
/// 호출부는 `showDialog(barrierDismissible: false)`로 바깥 탭 닫힘을 막고,
/// 이 Dialog의 PopScope가 저장 중 뒤로가기를 막습니다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const _maxCommentLength = 500;

  late int _score = widget.initialScore;

  // build() 안에서 만들면 setState마다 입력이 초기화되므로 State에서 한 번만 만듭니다.
  // comment가 null이면 빈 칸으로 시작합니다.
  late final _commentController =
      TextEditingController(text: widget.initialComment ?? '');

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          widget.initialScore > 0 ? '평점을 수정해주세요' : '평점을 남겨주세요',
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovieRatingInput(
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
              const SizedBox(height: 8),
              Text(
                _score == 0 ? '별을 눌러 평가해주세요' : '$_score점',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: _maxCommentLength,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: '코멘트를 남겨보세요 (선택)',
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed:
                _isSubmitting ? null : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '확인',
            isLoading: _isSubmitting,
            // 별점을 고르기 전에는 코멘트만 입력해도 누를 수 없습니다.
            onPressed: _score > 0 && !_isSubmitting ? _onConfirm : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    final trimmed = _commentController.text.trim();
    if (trimmed.length > _maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      // 빈 문자열은 null로 바꿔 보냅니다.
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on UserFacingException catch (error) {
      // 400/403/404/409는 서버 message로 구별해서 보여줍니다.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = error.message;
      });
    } catch (error) {
      // 실패해도 로딩을 반드시 해제해야 다시 시도할 수 있습니다.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }
}
