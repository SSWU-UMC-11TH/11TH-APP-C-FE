import 'package:flutter/material.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      theme: AppTheme.light, // 기존 테마 이름에 맞게 수정
    );
  }
}