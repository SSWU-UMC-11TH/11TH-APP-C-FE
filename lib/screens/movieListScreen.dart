import 'package:flutter/material.dart';
import '../data/mock_movie.dart';
import 'package:movielog/widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = [
    '전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스', '다큐멘터리',
  ];
  String selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final filtered = selectedGenre == '전체'
        ? mockMovies
        : mockMovies.where((m) => m.genre == selectedGenre).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('영화',
            style: TextStyle(
                color: primary, fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres[index];
                final selected = selectedGenre == genre;
                return ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                  selectedColor: primary,
                  backgroundColor: const Color(0xFFE9E3F0),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => selectedGenre = genre),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  MovieCard(movie: filtered[index]),
            ),
          ),
        ],
      ),
    );
  }
}