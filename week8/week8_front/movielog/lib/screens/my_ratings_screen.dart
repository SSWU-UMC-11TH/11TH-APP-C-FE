import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// [6~8주차] 마이페이지 → 내가 등록한 평점 (View).
///
/// [8주차] memberId로 조회하지 않는다. 현재 로그인 세션에서 등록한 평점을 보여주고,
/// 각 평점 카드 오른쪽의 버튼으로 v7 PATCH/DELETE(토큰 기반)를 호출한다.
/// 앱 재시작 뒤 기존 내 평점 전체 복원은 v7 계약(토큰 기반 목록 GET 없음)상 하지 않는다.
/// root Navigator 위에 열리므로 하단 NavigationBar가 보이지 않는다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final showSelectionBar = viewModel.isEditMode &&
            viewModel.status == MyRatingsLoadStatus.success;

        // [Challenge] 다중 삭제 중에는 화면 이탈을 막고 로딩 오버레이를 올린다.
        return PopScope(
          canPop: !viewModel.isDeletingSelected,
          child: LoadingOverlay(
            isLoading: viewModel.isDeletingSelected,
            child: Scaffold(
              appBar: AppBar(
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: const BackButton(color: AppColors.primary),
                title: const Text(
                  '내가 등록한 평점',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              body: switch (viewModel.status) {
                MyRatingsLoadStatus.idle ||
                MyRatingsLoadStatus.loading =>
                  const _RatingsLoading(),
                MyRatingsLoadStatus.empty => const _RatingsEmpty(),
                MyRatingsLoadStatus.success => _RatingsList(
                    viewModel: viewModel,
                    onEdit: (rating) => onEditPressed(context, rating),
                    onDelete: (rating) => onDeletePressed(context, rating),
                  ),
              },
              // 하단 NavigationBar는 두지 않는다. 편집 모드에서만 삭제 버튼을 띄운다.
              bottomNavigationBar: showSelectionBar
                  ? _DeleteSelectedBar(
                      count: viewModel.selectedRatingIds.length,
                      onPressed: viewModel.selectedRatingIds.isEmpty
                          ? null
                          : () => onDeleteSelectedPressed(context),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// 실패 문구를 Snackbar로 보여준다.
///
/// 세션 만료(401)일 때는 ViewModel이 문구를 비워 두므로 아무것도 띄우지 않는다.
/// (로그인 화면이 만료를 안내한다)
void _showFailure(ScaffoldMessengerState messenger, String? message) {
  if (message == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// [7주차] 수정: 등록과 같은 RatingDialog를 기존 별점·코멘트로 채워서 다시 연다.
///
/// [8주차] PATCH는 전체 교체이므로 Dialog를 열 때 항상 기존 score·comment를 채우고
/// 두 값을 함께 보낸다. 성공하면 수정 result의 Rating 객체로 카드가 갱신된다.
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  // await 뒤에 목록이 다시 그려질 수 있으므로 필요한 것을 먼저 꺼내 둔다.
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작한다.
      onSubmit: (score, comment) async {
        final saved = await viewModel.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        );
        if (saved) return;
        // 400·403·404를 code로 구분한 문구를 알린다. 403이어도 로그아웃하지 않는다.
        _showFailure(messenger, viewModel.message);
        // 서버에 없는 평점(404)이라 목록에서 빠졌으면 Dialog를 닫는다.
        if (!viewModel.hasRating(rating.ratingId)) return;
        // 그 밖의 실패는 Dialog를 닫지 않고 입력을 그대로 둔다.
        throw StateError('평점을 수정하지 못했습니다.');
      },
    ),
  );
}

/// [7주차] 단일 삭제: 확인 Dialog를 띄우고, 삭제 요청이 끝날 때까지 Dialog를 유지한다.
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막는다.
    builder: (_) => _DeleteRatingDialog(
      // true를 반환하면 Dialog가 닫힌다.
      onConfirm: () async {
        final deleted = await viewModel.deleteRating(rating.ratingId);
        if (deleted) return true;
        // 403·404를 code로 구분한 문구를 알린다.
        _showFailure(messenger, viewModel.message);
        // 서버에 없는 평점(404)이라 목록에서 빠졌으면 Dialog를 닫는다.
        return !viewModel.hasRating(rating.ratingId);
      },
    ),
  );
}

/// [Challenge] 다중 삭제: 확인 Dialog는 삭제 여부만 묻고 바로 닫힌다.
/// 삭제 요청은 Dialog가 닫힌 뒤 화면(ViewModel)이 이어받는다.
Future<void> onDeleteSelectedPressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final count = viewModel.selectedRatingIds.length;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ConfirmDeleteDialog(
      title: '선택한 평점 $count개를 삭제할까요?',
      onCancel: () => Navigator.pop(dialogContext, false),
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  // 여기서 Dialog는 이미 닫혔다. 취소했으면 삭제 요청을 보내지 않는다.
  if (confirmed != true || !context.mounted) return;

  await viewModel.deleteSelectedRatings();

  // 일부만 실패하면 실패한 항목이 선택된 채로 남는다.
  if (viewModel.selectedRatingIds.isNotEmpty && viewModel.message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
  }
}

/// [7주차] 평점 삭제 확인 Dialog.
///
/// 삭제 API 요청 중에는 PopScope로 뒤로가기를 막고, 버튼을 로딩 상태로 바꾼다.
class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  /// 삭제 요청을 실행한다. true면 Dialog를 닫고, false면 열어 둔 채 다시 시도할 수 있다.
  final Future<bool> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: _ConfirmDeleteDialog(
        title: '평점을 삭제할까요?',
        isLoading: _isDeleting,
        // 취소는 onConfirm을 호출하지 않으므로 삭제 요청도 없다.
        onCancel: _isDeleting ? null : () => Navigator.pop(context, false),
        onConfirm: _isDeleting ? null : _onConfirm,
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      final shouldClose = await widget.onConfirm();
      if (!mounted) return;
      if (shouldClose) {
        Navigator.pop(context, true);
      } else {
        // 실패해도 로딩을 풀어야 다시 시도할 수 있다.
        setState(() => _isDeleting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.')),
        );
    }
  }
}

/// [7주차] 삭제 확인 Dialog의 공통 모양. (Figma W7-REQ 평점 삭제 확인)
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              '삭제한 평점은 복구할 수 없습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: MovieLogButton(
                    label: '취소',
                    width: double.infinity,
                    isSecondary: true,
                    radius: 8,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MovieLogButton(
                    label: '삭제',
                    width: double.infinity,
                    radius: 8,
                    isLoading: isLoading,
                    onPressed: onConfirm,
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

/// [Loading]
class _RatingsLoading extends StatelessWidget {
  const _RatingsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

/// [Empty] 현재 세션에서 등록한 평점이 없으면 안내 문구만 보여준다.
/// 마지막 평점을 삭제해도 이 화면이 된다.
class _RatingsEmpty extends StatelessWidget {
  const _RatingsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 48, color: AppColors.textSub),
            SizedBox(height: 12),
            Text(
              '아직 등록한 평점이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              '이번 로그인에서 남긴 평점이 여기에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

/// [Success] (Figma W7-REQ / W7-CH)
class _RatingsList extends StatelessWidget {
  const _RatingsList({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final MyRatingsViewModel viewModel;
  final ValueChanged<RatingDto> onEdit;
  final ValueChanged<RatingDto> onDelete;

  @override
  Widget build(BuildContext context) {
    final ratings = viewModel.ratings;
    final notice = viewModel.message;
    final isEditMode = viewModel.isEditMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // [Challenge] 같은 줄 왼쪽: 선택한 카드 수 / 오른쪽: 편집 ↔ 취소
        Row(
          children: [
            Expanded(
              child: isEditMode
                  ? Text(
                      '${viewModel.selectedRatingIds.length}개 선택됨',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.violet,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed:
                  isEditMode ? viewModel.exitEditMode : viewModel.enterEditMode,
              child: Text(isEditMode ? '취소' : '편집'),
            ),
          ],
        ),
        if (notice != null) ...[
          Text(notice, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < ratings.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _RatingCard(
            entry: ratings[i],
            isEditMode: isEditMode,
            isSelected: viewModel.selectedRatingIds
                .contains(ratings[i].rating.ratingId),
            onToggle: () =>
                viewModel.toggleSelection(ratings[i].rating.ratingId),
            onEdit: () => onEdit(ratings[i].rating),
            onDelete: () => onDelete(ratings[i].rating),
          ),
        ],
      ],
    );
  }
}

/// 평점 카드 하나.
///
/// - 기본: 포스터 · 제목 · "별점 N / 5" · 코멘트 + 오른쪽 수정·삭제 버튼
/// - [Challenge] 편집 모드: 왼쪽 CheckBox · "제목 · 별점 N" · 코멘트
class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.isEditMode,
    required this.isSelected,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingWithMovie entry;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;
    // TMDB에서 영화를 찾지 못해도 어떤 영화의 평점인지 알 수 있게 movieId로 표시한다.
    final title = movie?.title ?? '영화 #${rating.movieId}';

    final card = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: isEditMode
          ? Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.violet,
                  onChanged: (_) => onToggle(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title · 별점 ${rating.score}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (comment != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie?.posterPath == null
                      ? Container(
                          width: 52,
                          height: 78,
                          color: AppColors.posterPlaceholder,
                        )
                      : TmdbPosterImage(
                          posterPath: movie?.posterPath,
                          width: 52,
                          height: 78,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '별점 ${rating.score} / 5',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.violet,
                          ),
                        ),
                        // comment가 null이면 코멘트 줄을 그리지 않는다.
                        if (comment != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        if (movie == null) ...[
                          const SizedBox(height: 6),
                          const Text(
                            '포스터 정보 없음',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 목록은 현재 세션에서 본인이 등록한 평점이므로 모든 카드에 수정·삭제 버튼을 둔다.
                Column(
                  children: [
                    _SmallActionButton(
                      label: '수정',
                      background: AppColors.lavenderLight,
                      foreground: AppColors.violet,
                      onPressed: onEdit,
                    ),
                    const SizedBox(height: 6),
                    _SmallActionButton(
                      label: '삭제',
                      background: AppColors.dangerSoft,
                      foreground: AppColors.danger,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
    );

    if (!isEditMode) return card;
    // 편집 모드에서는 카드 어디를 눌러도 선택이 바뀐다.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: card,
    );
  }
}

/// 카드 오른쪽의 작은 수정·삭제 버튼.
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: background,
          foregroundColor: foreground,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// [Challenge] 편집 모드 하단의 "선택한 N개 삭제" 버튼. 선택이 1개 이상일 때만 활성화된다.
class _DeleteSelectedBar extends StatelessWidget {
  const _DeleteSelectedBar({required this.count, required this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: MovieLogButton(
          label: '선택한 $count개 삭제',
          width: double.infinity,
          radius: 22,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
