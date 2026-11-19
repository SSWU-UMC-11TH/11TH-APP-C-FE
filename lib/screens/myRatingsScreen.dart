import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/empty_view.dart';
import 'package:movielog/widgets/loading_overlay.dart';
import 'package:movielog/widgets/rating_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // 기존 값을 채워 score·comment를 함께 전송
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
    if (confirmed != true) return;

    final error = await vm.deleteRating(rating);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(error ?? '평점을 삭제했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final vm = context.watch<MyRatingsViewModel>();

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
          child: vm.ratings.isEmpty
              ? const EmptyView(
                  message: '이번 로그인에서 등록한 평점이 없어요.\n(재시작 뒤 기존 평점 복원은 지원하지 않아요)')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text('이번 로그인에서 등록한 평점만 표시돼요.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.ratings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = vm.ratings[index];
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
        ),
      ),
    );
  }
}