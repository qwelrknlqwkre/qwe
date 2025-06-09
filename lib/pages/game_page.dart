import 'package:flutter/material.dart';
import '../utils/matgo_engine.dart';
import '../utils/gostop_3p_engine.dart';
import '../models/card_model.dart';
import 'gostop_board.dart';

class GamePage extends StatefulWidget {
  final String mode;
  const GamePage({required this.mode, super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late dynamic engine;
  int playerIndex = 1;

  @override
  void initState() {
    super.initState();
    engine = widget.mode == 'matgo' ? MatgoEngine() : GoStop3PEngine();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAiTurn());
  }

  void onCardTap(GoStopCard card) async {
    if (engine.isGameOver() || engine.getCurrentPlayer() != 1) return;

    engine.getHand(1).removeWhere((c) => c.id == card.id);
    engine.playTurn(card);
    setState(() {});

    if (engine.isAwaitingGoStop()) {
      final score = engine.calculateScore('player1');
      final result = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("고 or 스톱?"),
          content: Text("현재 점수: $score점\n고하시겠습니까?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 'go'), child: const Text('고')),
            TextButton(onPressed: () => Navigator.pop(context, 'stop'), child: const Text('스톱')),
          ],
        ),
      );

      if (result == 'go') {
        engine.declareGo();
        setState(() {
          playerIndex = 2;
        });
        await _maybeRunAiTurn();
        return;
      } else if (result == 'stop') {
        engine.declareStop();
        setState(() {});
        _showGameOverDialog();
        return;
      }
    }

    await _postTurnActions();
  }

  Future<void> _postTurnActions() async {
    if (engine.isGameOver()) {
      _showGameOverDialog();
      return;
    }

    setState(() {
      playerIndex = widget.mode == 'matgo' ? (playerIndex == 1 ? 2 : 1) : (playerIndex % 3) + 1;
    });

    await _maybeRunAiTurn();
  }

  Future<void> _maybeRunAiTurn() async {
    final cp = engine.getCurrentPlayer();
    if (cp != 1 && !engine.isGameOver()) {
      await Future.delayed(const Duration(milliseconds: 800));
      final hand = engine.getHand(cp);
      if (hand.isNotEmpty) {
        engine.playTurn(hand.first);
        setState(() {});
        if (engine.isAwaitingGoStop()) {
          final score = engine.calculateScore('player$cp');
          final result = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("고 or 스톱?"),
              content: Text("현재 점수: $score점\n고하시겠습니까?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, 'go'), child: const Text('고')),
                TextButton(onPressed: () => Navigator.pop(context, 'stop'), child: const Text('스톱')),
              ],
            ),
          );

          if (result == 'go') {
            engine.declareGo();
            setState(() {});
          } else if (result == 'stop') {
            engine.declareStop();
            setState(() {});
            _showGameOverDialog();
            return;
          }
        }
        await _postTurnActions();
      }
    }
  }

  void _showGameOverDialog() {
    final result = engine.getResult();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게임 종료'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                engine = widget.mode == 'matgo' ? MatgoEngine() : GoStop3PEngine();
                playerIndex = 1;
                WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAiTurn());
              });
            },
            child: const Text('다시 시작'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoStopBoard(
      myHand: engine.getHand(1),
      myCaptured: engine.getCaptured(1),
      opponentHand: engine.getHand(2),
      opponentCaptured: engine.getCaptured(2),
      fieldCards: engine.getField(),
      myScore: engine.calculateScore('player1'),
      opponentScore: engine.calculateScore('player2'),
    );
  }
}