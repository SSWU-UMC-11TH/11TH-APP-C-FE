import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_storage.dart';
import 'package:movielog/widgets/empty_view.dart';
import 'package:movielog/widgets/error_view.dart';
import 'package:movielog/widgets/loading_view.dart';
import 'package:movielog/widgets/movie_grid.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = [
    '전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스', '다큐멘터리',
  ];

  final _genreStorage = GenreStorage();

  late Future<List<Movie>> _moviesFuture;
  String selectedGenre = '전체';

  @override
  void initState() {
    super.initState();
    // Future는 build가 아닌 initState에서 한 번만 생성
    _moviesFuture = movieService.fetchMovies();
    _restoreGenre();
  }

  Future<void> _restoreGenre() async {
    try {
      final saved = await _genreStorage.load();
      if (!mounted) return;
      if (saved != null && genres.contains(saved)) {
        setState(() => selectedGenre = saved);
      }
    } catch (_) {
      // 저장값을 못 읽어도 기본값('전체')으로 계속 진행
    }
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => selectedGenre = genre);
    try {
      await _genreStorage.save(genre);
    } catch (_) {
      // 저장 실패는 화면 동작에 영향 없음
    }
  }

  // 재시도할 때만 새 Future 생성
  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                  onSelected: (_) => _selectGenre(genre),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  return ErrorView(onRetry: _retry);
                }

                final movies = snapshot.data ?? [];
                if (movies.isEmpty) {
                  return const EmptyView(message: '아직 등록된 영화가 없어요');
                }

                final filtered = selectedGenre == '전체'
                    ? movies
                    : movies.where((m) => m.genre == selectedGenre).toList();
                if (filtered.isEmpty) {
                  return const EmptyView(message: '이 장르의 영화가 아직 없어요');
                }

                return MovieGrid(movies: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }
}