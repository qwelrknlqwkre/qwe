import 'dart:math';
import '../data/card_data.dart';
import '../models/card_model.dart';

class DeckManager {
  final int playerCount;
  final bool isMatgo;
  final List<GoStopCard> fullDeck;
  final Map<int, List<GoStopCard>> playerHands = {};
  final List<GoStopCard> fieldCards = [];
  final List<GoStopCard> drawPile = [];

  DeckManager({required this.playerCount, this.isMatgo = false})
      : fullDeck = List.from(
            goStopCards.where((card) => card.type != CardType.back)) {
    if (playerCount < 2 || playerCount > 3) {
      throw Exception('GoStop supports only 2 or 3 players.');
    }
    _setupGame();
  }

  void _setupGame() {
    final random = Random();
    fullDeck.shuffle(random);

    final int cardsPerPlayer = isMatgo ? 10 : 7;

    // 1차 분배
    for (int p = 0; p < playerCount; p++) {
      playerHands[p] = fullDeck.sublist(0, cardsPerPlayer);
      fullDeck.removeRange(0, cardsPerPlayer);
    }

    // 바닥카드 6장
    fieldCards.addAll(fullDeck.sublist(0, 6));
    fullDeck.removeRange(0, 6);

    // 나머지는 더미
    drawPile.addAll(fullDeck);
  }

  List<GoStopCard> getPlayerHand(int playerIndex) {
    return playerHands[playerIndex] ?? [];
  }

  List<GoStopCard> getFieldCards() => fieldCards;
  List<GoStopCard> getDrawPile() => drawPile;
}