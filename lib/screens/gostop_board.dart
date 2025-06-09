import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import '../models/card_model.dart';

class GoStopBoard extends StatelessWidget {
  final List<GoStopCard> myHand;
  final List<GoStopCard> myCaptured;
  final List<GoStopCard> opponentHand;
  final List<GoStopCard> opponentCaptured;
  final List<GoStopCard> fieldCards;
  final int myScore;
  final int opponentScore;
  final void Function(GoStopCard)? onCardTap;

  const GoStopBoard({
    super.key,
    required this.myHand,
    required this.myCaptured,
    required this.opponentHand,
    required this.opponentCaptured,
    required this.fieldCards,
    required this.myScore,
    required this.opponentScore,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2f4f2f), // 녹색 바탕
      body: SafeArea(
        child: Column(
          children: [
            _buildOpponentRow(),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text("현재 턴: 플레이어 ${myScore > opponentScore ? 1 : 2}", style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: fieldCards.map((card) => CardWidget(card: card)).toList(),
                  ),
                ],
              ),
            ),
            _buildMyRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentRow() {
    return Column(
      children: [
        Text("플레이어 2 점수: $opponentScore점", style: const TextStyle(color: Colors.white)),
        Wrap(
          spacing: 4,
          children: opponentHand.map((_) => CardWidget(
            card: GoStopCard(id: 0, month: 0, type: CardType.back, name: 'Back', imageUrl: 'assets/cards/back.png'),
            showBack: true,
          )).toList(),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: opponentCaptured.map((c) => CardWidget(card: c, width: 30)).toList(),
        ),
      ],
    );
  }

  Widget _buildMyRow() {
    return Column(
      children: [
        Wrap(
          spacing: 4,
          children: myCaptured.map((c) => CardWidget(card: c, width: 36)).toList(),
        ),
        const SizedBox(height: 8),
        Text("플레이어 1 점수: $myScore점", style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: myHand.map((card) => GestureDetector(
            onTap: onCardTap != null ? () => onCardTap!(card) : null,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: 1.0,
              child: CardWidget(card: card),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}