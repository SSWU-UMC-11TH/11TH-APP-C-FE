import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/widgets/movielog_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              const Text(
                'FLUTTER 8주차',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF494551),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 64),
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B1C1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF494551),
                ),
              ),
              const Spacer(),
              if (onRetry == null)
                const CircularProgressIndicator() // 세션 확인 중
              else ...[
                Text(message ?? '로그인 상태를 확인하지 못했어요.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                MovieLogButton(
                  label: '다시 시도',
                  width: double.infinity,
                  onPressed: onRetry,
                ),
              ],
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}