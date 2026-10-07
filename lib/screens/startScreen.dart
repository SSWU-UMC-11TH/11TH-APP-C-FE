import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 64),
            const Text(
              'FLUTTER 1주차',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF494551),
                fontWeight: FontWeight(500),

              ),
            ),
            SizedBox(height: 64),
            // const Icon(
            //   Icons.movie_outlined,
            //   size: 80,
            //   color: Colors.deepPurple,
            //   semanticLabel: '영화 아이콘',
            // ),
            SvgPicture.asset(
              'assets/logos/movielog_logo.svg',
              width: 72,
              height: 72,
              semanticsLabel: 'MovieLog 로고',
              ),
            const SizedBox(height: 72), 

            const Text(
              '영화의 순간을\n기록하세요',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B1C1A)
              ),
              
            ),
            const SizedBox(height: 8), 

            const Text(
              '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
               textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF494551),
              ),
            ),
          Spacer(),
          SizedBox(
            width: 326,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                context.go('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F378A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                ),
            ),
        ),
            SizedBox(height: 56),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

