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
                    builder: (_) => GamePage(mode: 'matgo'),
                  ),
                );
              },
              child: const Text('2인 맞고 시작'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => GamePage(mode: 'gostop3p'),
                  ),
                );
              },
              child: const Text('3인 고스톱 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
