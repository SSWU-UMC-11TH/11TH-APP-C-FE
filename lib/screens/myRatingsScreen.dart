import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/empty_view.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_overlay.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/rating_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  // 목록이 다시 그려지면 카드의 context가 사라지므로,
  // await 뒤에는 context 대신 미리 잡아 둔 messenger를 사용합니다.
  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // null이면 빈 칸으로 시작
        // 코멘트를 비우고 저장하면 후기가 삭제됩니다.
        onSubmit: (score, comment) =>
            vm.updateRating(rating: rating, score: score, comment: comment),
      ),
    );

    if (saved != true) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('평점을 수정했어요.')));
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    // 취소하면 삭제 API 요청을 보내지 않음
    if (confirmed != true) return;

    final error = await vm.deleteRating(rating);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(error ?? '평점을 삭제했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final vm = context.watch<MyRatingsViewModel>();

    // bottomNavigationBar를 넣지 않음
    return PopScope(
      canPop: !vm.isBusy,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('내가 등록한 평점',
              style: TextStyle(
                  color: primary, fontWeight: FontWeight.w700, fontSize: 20)),
        ),
        body: LoadingOverlay(
          isLoading: vm.isDeleting,
          child: _buildBody(context, vm),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyRatingsViewModel vm) {
    return switch (vm.status) {
      MyRatingsLoadStatus.idle ||
      MyRatingsLoadStatus.loading =>
        const LoadingView(),
      MyRatingsLoadStatus.error => ErrorView(
          message: vm.message ?? '평점을 불러오지 못했습니다.',
          // 저장은 끝났고 GET만 실패한 경우에도 GET만 다시 요청
          onRetry: () => context.read<MyRatingsViewModel>().load(),
        ),
      MyRatingsLoadStatus.empty =>
        const EmptyView(message: '아직 등록한 평점이 없어요'),
      MyRatingsLoadStatus.success => Column(
          children: [
            if (vm.message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(vm.message!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vm.ratings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final RatingWithMovie entry = vm.ratings[index];
                  return RatingCard(
                    entry: entry,
                    onEdit: () => _edit(context, entry.rating),
                    onDelete: () => _delete(context, entry.rating),
                  );
                },
              ),
            ),
          ],
        ),
    };
  }
}