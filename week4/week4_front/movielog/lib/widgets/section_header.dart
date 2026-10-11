import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 홈 화면 구역의 제목 줄. onMoreTap을 주면 오른쪽에 '전체보기 >'가 생긴다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onMoreTap});

  final String title;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (onMoreTap != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMoreTap,
              child: const Row(
                children: [
                  Text(
                    '전체보기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}