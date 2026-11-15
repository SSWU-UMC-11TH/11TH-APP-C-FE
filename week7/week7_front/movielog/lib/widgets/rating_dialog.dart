import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../theme/app_theme.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점과 코멘트를 입력하는 커스텀 Dialog. (Figma W7-01)
///
/// [7주차] 저장 로직을 [onSubmit] 콜백으로 받아 Dialog 안에서 실행한다.
/// - onSubmit이 예외 없이 끝나면 true를 반환하며 닫힌다.
/// - 취소를 누르면 onSubmit을 호출하지 않고 false를 반환한다. (API 요청 없음)
/// - 저장에 실패하면 Dialog를 닫지 않고 입력을 그대로 둔 채 오류 문구를 보여준다.
/// - 저장 중에는 PopScope로 뒤로가기를 막는다.
///   바깥 탭은 showDialog의 `barrierDismissible: false`로 함께 막는다.
///
/// 평점 등록(영화 상세)과 수정(내가 등록한 평점)이 같은 Dialog를 쓴다.
/// 수정할 때는 [initialScore]·[initialComment]에 기존 값을 넣는다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final int initialScore;

  /// null이면 TextField가 빈 칸으로 시작한다.
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;

  // build() 안에서 만들면 setState마다 새로 만들어져 입력하던 코멘트가 사라진다.
  // State가 살아 있는 동안 한 번만 만든다.
  late final _commentController =
      TextEditingController(text: widget.initialComment ?? '');
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            // Column이 화면 전체가 아니라 내용만큼만 높이를 갖게 한다.
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '평점을 남겨주세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Center(
                child: MovieRatingInput(
                  rating: _score.toDouble(),
                  enabled: !_isSubmitting,
                  onChanged: (value) => setState(
                    () => _score = validateServerScore(value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '코멘트 (선택, 최대 500자)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 3,
                maxLength: 500,
                enabled: !_isSubmitting,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '이 영화의 인상적인 장면은...',
                  hintStyle: AppTextStyles.bodySmall,
                  filled: true,
                  fillColor: AppColors.lavenderLight,
                  // 최대 글자 수는 라벨로 안내하므로 카운터는 숨긴다.
                  counterText: '',
                  contentPadding: const EdgeInsets.all(12),
                  border: _border(AppColors.cardBorder),
                  enabledBorder: _border(AppColors.cardBorder),
                  disabledBorder: _border(AppColors.cardBorder),
                  focusedBorder: _border(AppColors.violet),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '취소',
                      width: double.infinity,
                      isSecondary: true,
                      radius: 22,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MovieLogButton(
                      label: '확인',
                      width: double.infinity,
                      radius: 22,
                      isLoading: _isSubmitting,
                      // 별점을 선택해야 확인할 수 있다. (코멘트만 입력해서는 안 된다)
                      onPressed: _score > 0 && !_isSubmitting ? _onConfirm : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    // 빈 문자열은 null로 바꿔 요청한다.
    final trimmed = _commentController.text.trim();
    if (trimmed.length > 500) {
      setState(() {
        _isSubmitting = false;
        _errorText = '코멘트는 500자 이하로 입력해 주세요.';
      });
      return;
    }
    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      // 실패해도 로딩을 반드시 풀어야 다시 시도할 수 있다. 입력값은 그대로 남는다.
      setState(() {
        _isSubmitting = false;
        _errorText = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }
}
