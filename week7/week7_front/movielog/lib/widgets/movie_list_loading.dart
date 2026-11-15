import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'movie_grid.dart';

/// [Loading] 빈 화면 대신 영화 카드 모양의 Skeleton을 보여준다.
class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  @override
  State<MovieListLoading> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '영화 목록을 불러오는 중',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: movieGridPadding,
            itemCount: 6,
            gridDelegate: movieGridDelegate,
            itemBuilder: (context, index) => const _SkeletonCard(),
          ),
        ),
      ),
    );
  }
}

/// MovieCard와 같은 구조(포스터 + 제목 + 보조 정보)의 자리 표시.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _SkeletonBox(radius: 12)),
        SizedBox(height: 10),
        _SkeletonBox(width: 110, height: 15),
        SizedBox(height: 6),
        _SkeletonBox(width: 70, height: 12),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, this.height, this.radius = 4});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}