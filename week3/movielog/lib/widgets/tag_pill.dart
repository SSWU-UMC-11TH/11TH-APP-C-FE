import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 상세의 태그, 마이페이지의 선호 장르에 쓰는 작은 알약 모양 라벨.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.color = AppColors.chip,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}