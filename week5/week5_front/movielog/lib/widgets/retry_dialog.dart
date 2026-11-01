import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [Challenge] 영화 목록 요청 실패 시 재시도 / 취소를 묻는 Dialog. (Figma W5-01)
///
/// 다시 시도를 누르면 true, 취소하거나 바깥을 눌러 닫으면 false/null을 돌려준다.
class RetryDialog extends StatelessWidget {
  const RetryDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => const RetryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.lavenderLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.replay,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '영화를 불러오지 못했어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: '취소',
                    backgroundColor: AppColors.lavenderLight,
                    foregroundColor: AppColors.primary,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PillButton(
                    label: '다시 시도',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 양 끝이 둥근 Dialog 버튼.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}