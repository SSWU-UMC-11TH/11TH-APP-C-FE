import 'package:flutter/material.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/empty_view.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/rating_card.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // bottomNavigationBar를 넣지 않음. 뒤로 가기는 push로 열렸을 때 자동 생성
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('내가 등록한 평점',
            style: TextStyle(
                color: primary, fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, vm, child) {
          return switch (vm.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading =>
              const LoadingView(),
            MyRatingsLoadStatus.error => ErrorView(
                message: vm.message ?? '평점을 불러오지 못했습니다.',
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
                      itemBuilder: (context, index) =>
                          RatingCard(entry: vm.ratings[index]),
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}