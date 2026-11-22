import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env를 다 읽기 전에 Token을 꺼내면 빈 값이 나오므로 runApp 전에 await한다.
  await dotenv.load(fileName: '.env');

  runApp(const MovieLogApp());
}
