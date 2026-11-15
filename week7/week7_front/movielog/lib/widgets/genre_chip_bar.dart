import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_theme.dart';

/// [Required] 가로로 스크롤되는 장르 Chip 목록. '전체' + Genre API의 장르.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedGenreIds,
    required this.onSelected,
    this.enabled = true,
  });

  final List<TmdbGenreDto> genres;

  /// null이면 '전체'. 여러 개가 골라져 있으면(BottomSheet) 어떤 Chip도 강조하지 않는다.
  final List<int>? selectedGenreIds;

  /// '전체'를 누르면 null이 전달된다.
  final ValueChanged<TmdbGenreDto?> onSelected;

  /// false면 Chip을 눌러도 아무 일도 일어나지 않는다. (Discover 요청 중)
  final bool enabled;

  bool _isSelected(TmdbGenreDto? genre) {
    final selected = selectedGenreIds;
    if (genre == null) return selected == null || selected.isEmpty;
    return selected != null &&
        selected.length == 1 &&
        selected.first == genre.id;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // 0번은 '전체', 그 뒤로 장르가 이어진다.
          itemCount: genres.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final TmdbGenreDto? genre = index == 0 ? null : genres[index - 1];
            final isSelected = _isSelected(genre);

            return GestureDetector(
              onTap: enabled ? () => onSelected(genre) : null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  genre?.name ?? '전체',
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
      ),
    );
  }
}
