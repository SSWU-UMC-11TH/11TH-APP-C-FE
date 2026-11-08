import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [Challenge] 장르를 여러 개 고르는 BottomSheet.
///
/// - 위아래로 드래그해 높이를 조절한다 (DraggableScrollableSheet).
/// - 목록만 스크롤되고 확인 버튼은 하단에 고정된다 (Column + Expanded).
/// - Checkbox를 바꾸는 동안에는 Sheet 내부 상태만 바뀌고,
///   확인을 눌러야 선택 결과가 Navigator.pop으로 바깥에 전달된다.
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelection,
  });

  final List<String> genres;
  final Set<String> initialSelection;

  /// 확인을 누르면 선택된 장르를, 그냥 닫으면 null을 돌려준다.
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<String> genres,
    required Set<String> initialSelection,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      // DraggableScrollableSheet가 화면 절반 이상으로 커질 수 있게 한다.
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => GenreFilterSheet(
        genres: genres,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  // 적용된 필터의 복사본. 확인 전까지는 이 값만 바뀐다.
  late final Set<String> _selected = {...widget.initialSelection};

  void _toggle(String genre, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(genre);
      } else {
        _selected.remove(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '장르 필터',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '여러 장르를 선택할 수 있어요',
                    style: TextStyle(fontSize: 13, color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            // 목록 영역만 스크롤된다.
            Expanded(
              child: ListView.builder(
                // 목록 스크롤과 Sheet 드래그가 자연스럽게 이어지도록 연결한다.
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.genres.length,
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  return CheckboxListTile(
                    dense: true,
                    title: Text(genre, style: const TextStyle(fontSize: 15)),
                    value: _selected.contains(genre),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) => _toggle(genre, checked ?? false),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // 목록 바깥에 있으므로 스크롤해도 항상 하단에 보인다.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // 아무것도 고르지 않고 확인하면 빈 Set → 전체 목록.
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}