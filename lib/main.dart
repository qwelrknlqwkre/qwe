import 'package:flutter/material.dart';
import 'screens/game_setup_page.dart';

void main() {
  runApp(const GoStopApp());
}

class GoStopApp extends StatelessWidget {
  const GoStopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '고스톱 MVP',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const GameSetupPage(),
    );
  }
}
