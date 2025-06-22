// screens/game_setup_page.dart

import 'package:flutter/material.dart';
import 'game_page.dart';

class GameSetupPage extends StatelessWidget {
  const GameSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고스톱 모드 선택')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const GamePage(mode: 'ai'),
                  ),
                );
              },
              child: const Text('AI 대전'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const GamePage(mode: '2p'),
                  ),
                );
              },
              child: const Text('2인 대전(사람 vs 사람)'),
            ),
          ],
        ),
      ),
    );
  }
}
