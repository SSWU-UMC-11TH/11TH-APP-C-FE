import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../widgets/movielog_button.dart';

/// [8주차] 앱 시작 초기화 전용 화면. (Figma W8-01 · W8-02)
///
/// 시작 화면의 로고·제목·설명 레이아웃을 재사용하고, 하단 '시작하기' 버튼 자리를
/// 로딩/재시도 상태로 바꿨다.
/// - [onRetry]가 없으면 세션 확인 중(initializing): 인디케이터
/// - [onRetry]가 있으면 세션 확인 실패(retryRequired): 안내 문구 + 다시 시도 버튼
///
/// 두 상태가 같은 레이아웃을 쓰므로 화면이 튀지 않는다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'FLUTTER 8주차',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 64),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              if (onRetry == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                Column(
                  children: [
                    Text(
                      message ?? '로그인 상태를 확인하지 못했어요.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    MovieLogButton(
                      label: '다시 시도',
                      width: double.infinity,
                      onPressed: onRetry,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
