import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [Required] 가로로 스크롤되는 장르 Chip 목록. '전체' + 장르 중 하나만 선택된다.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;

  /// null이면 '전체'가 선택된 상태다.
  final String? selectedGenre;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // 0번은 '전체', 그 뒤로 장르가 이어진다.
        itemCount: genres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String? genre = index == 0 ? null : genres[index - 1];
          final isSelected = genre == selectedGenre;

          return GestureDetector(
            onTap: () => onSelected(genre),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.chip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                genre ?? '전체',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}