import 'package:flutter/material.dart';

import 'start_screen.dart';

/// 앱 전체 설정을 담당하는 Widget
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // 디자인 시스템 Primary 500
        ),
      ),
      home: const StartScreen(),
    );
  }
}