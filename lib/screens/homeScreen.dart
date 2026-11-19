import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_movie.dart';
import 'package:movielog/widgets/featured_movie_card.dart';
import 'package:movielog/widgets/popular_movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final featured = mockMovies.first;
    final popular = mockMovies.skip(1).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('MovieLog',
            style: TextStyle(
                color: primary, fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FeaturedMovieCard(movie: featured),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('인기 영화',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => context.go('/movies'),
                  child: const Text('전체보기 >'),
                ),
              ],
            ),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => PopularMovieCard(
                  movie: popular[index],
                  rank: index + 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}