import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/screens/signupScreen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'screens/startScreen.dart';
import 'screens/profileScreen.dart';
import 'theme/app_theme.dart';


class Movie {
  String title;
  
  Movie(this.title);
}


void main() {
  List<Movie> movies = [
  Movie('인셉션'),
  Movie('옵세션'),
  Movie('아바타'),
];

  for (var movie in movies) {
    print(movie.title);
  } 

  String? nickName;
  String safeName = nickName ?? '손님';

  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      home:   const SignUpScreen(),

    );
  }
}
