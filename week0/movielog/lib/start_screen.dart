import 'package:flutter/material.dart';

/// 앱을 처음 실행했을 때 보이는 시작 화면
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  // ── 디자인 시스템 Color Palette ───────────────────────
  static const _primary500 = Color(0xFF6750A4);
  static const _primary600 = Color(0xFF4F378B);
  static const _neutral100 = Color(0xFFFFFFFF);
  static const _neutral800 = Color(0xFF7A7582);
  static const _neutral900 = Color(0xFF1B1C1A);

  // ── 디자인 시스템 Typography ─────────────────────────
  /// Label Small · 11 / 16 / 0.5
  static const _labelSmall = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontWeight: FontWeight.bold,
    color: _neutral900,
  );

  /// Title Medium · 24 / 32 / 0
  static const _titleMedium = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    fontWeight: FontWeight.bold,
    color: _neutral900,
  );

  /// Body Medium · 14 / 20 / 0.25
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
    color: _neutral800,
  );

  /// Label Large (Button) · 14 / 20 / 0.1
  static const _labelLarge = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              // 남은 공간을 모두 차지하는 가운데 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'FLUTTER 0주차',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _labelSmall,
                    ),
                    const SizedBox(height: 28),
                    const Icon(
                      Icons.movie_outlined,
                      size: 72,
                      color: _primary500,
                      semanticLabel: 'MovieLog 로고',
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      '영화의 순간을\n기록하세요',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyMedium,
                    ),
                  ],
                ),
              ),

              // 화면 하단 고정 버튼
              ElevatedButton(
                onPressed: () {
                  debugPrint('시작하기 버튼을 눌렀습니다.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary600,
                  foregroundColor: _neutral100,
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: _labelLarge,
                ),
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}