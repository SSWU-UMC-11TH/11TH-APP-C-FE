import 'package:flutter/material.dart';

import '../data/movie.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _all = '전체';
  final _filters = const [_all, ...genres];
  String _selectedGenre = _all;

  List<Movie> get _filteredMovies {
    if (_selectedGenre == _all) return movies;
    return movies.where((movie) => movie.genre == _selectedGenre).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovies;

    return Scaffold(
      appBar: AppBar(title: const Text('영화')),
      body: Column(
        children: [
          // 장르 Chip: 가로 ListView
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = _filters[index];
                return ChoiceChip(
                  label: Text(genre),
                  selected: _selectedGenre == genre,
                  onSelected: (_) {
                    setState(() {
                      _selectedGenre = genre;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // 영화 목록: GridView
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('해당 장르의 영화가 없어요.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.55,
                    ),
                    itemBuilder: (context, index) {
                      return MovieCard(movie: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
