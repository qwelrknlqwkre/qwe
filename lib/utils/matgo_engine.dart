import 'dart:math';
import '../models/card_model.dart';
import 'event_evaluator.dart';
import 'deck_manager.dart';

class MatgoEngine {
  final Map<String, List<GoStopCard>> hands = {
    'player1': [],
    'player2': [],
  };
  final Map<String, List<GoStopCard>> captured = {
    'player1': [],
    'player2': [],
  };

  List<GoStopCard> field = [];
  List<GoStopCard> drawPile = [];

  int currentPlayer = 1;
  int goCount = 0;
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();

  bool ssangpiGiven = false;
  bool threepiGiven = false;

  bool awaitingGoStop = false;

  MatgoEngine() {
    _initializeGame();
  }

  void _initializeGame() {
    final deck = DeckManager(playerCount: 2, isMatgo: true);
    hands['player1'] = deck.getPlayerHand(0);
    hands['player2'] = deck.getPlayerHand(1);
    field = deck.getFieldCards();
    drawPile = deck.getDrawPile();
  }

  void playTurn(GoStopCard playedCard) {
    final playerKey = 'player$currentPlayer';
   // final opponentKey = currentPlayer == 1 ? 'player2' : 'player1';

    // 폭탄 체크
    if (_checkAndApplyBomb(playerKey, playedCard)) {
      if (_checkVictoryCondition(playerKey)) {
        awaitingGoStop = true;
      }
      return;
    }

    hands[playerKey]!.removeWhere((c) => c.id == playedCard.id);
    bool gotTtak = EventEvaluator.isTtak(playedCard, field);

    _handlePlay(playerKey, playedCard);

    if (drawPile.isNotEmpty) {
      final drawn = drawPile.removeAt(0);
      bool gotChok = EventEvaluator.isChok(playedCard, drawn, field);
      _handlePlay(playerKey, drawn);
      if (gotChok) _addBonusPi(playerKey);
    }

    if (gotTtak) _addBonusPi(playerKey);

    if (eventEvaluator.isPuk(playedCard, field)) {
      _addBonusPi(playerKey);
      if (eventEvaluator.isTriplePuk()) {
        gameOver = true;
        winner = playerKey;
        return;
      }
    }

    if (_checkVictoryCondition(playerKey)) {
      awaitingGoStop = true; // 🔥 사용자가 선택할 때까지 대기
    } else {
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    }
  }

  bool _checkAndApplyBomb(String playerKey, GoStopCard card) {
    final month = card.month;
    final myCards = hands[playerKey]!;
    final sameMonthCards = myCards.where((c) => c.month == month).toList();

    if (sameMonthCards.length >= 3) {
      final fieldMatch = field.firstWhere(
          (c) => c.month == month,
          orElse: () => GoStopCard(id: -1, month: 0, type: 'none', name: '', imageUrl: ''));

      if (fieldMatch.id != -1) {
        // 폭탄 적용
        field.remove(fieldMatch);
        fieldMatch.id != -1 ? captured[playerKey]!.add(fieldMatch) : null;

        final three = sameMonthCards.take(3).toList();
        for (var c in three) {
          hands[playerKey]!.removeWhere((e) => e.id == c.id);
        }
        captured[playerKey]!.addAll(three);

        // 상대 피 뺏기
        final opponentKey = playerKey == 'player1' ? 'player2' : 'player1';
        final opponentPi = captured[opponentKey]!
            .firstWhere((c) => c.type == '피', orElse: () => GoStopCard(id: -1, month: 0, type: '', name: '', imageUrl: ''));

        if (opponentPi.id != -1) {
          captured[opponentKey]!.removeWhere((c) => c.id == opponentPi.id);
          captured[playerKey]!.add(opponentPi);
        }

        return true;
      }
    }

    return false;
  }

  void _handlePlay(String playerKey, GoStopCard card) {
    final matches = field.where((c) => c.month == card.month).toList();

    if (matches.isEmpty) {
      field.add(card);
    } else if (matches.length == 1) {
      field.remove(matches.first);
      captured[playerKey]!.addAll([card, matches.first]);
    } else if (matches.length == 2) {
      final chosen = matches[Random().nextInt(2)];
      field.remove(chosen);
      captured[playerKey]!.addAll([card, chosen]);
    } else if (matches.length == 3) {
      field.removeWhere((c) => c.month == card.month);
      captured[playerKey]!.addAll([card, ...matches]);
    }
  }

  void _addBonusPi(String playerKey) {
    final List<GoStopCard> bonuses = [];

    if (!ssangpiGiven) {
      bonuses.add(GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ));
      ssangpiGiven = true;
    }

    if (!threepiGiven) {
      bonuses.add(GoStopCard(
        id: 992,
        month: 0,
        type: '피',
        name: '보너스(쓰리피)',
        imageUrl: 'assets/cards/bonus_3pi.png',
      ));
      threepiGiven = true;
    }

    captured[playerKey]!.addAll(bonuses);
  }

  bool _checkVictoryCondition(String playerKey) {
    final score = calculateScore(playerKey);
    return score >= 7;
  }

  int calculateScore(String playerKey) {
    final cards = captured[playerKey]!;
    int score = 0;

    int gwang = cards.where((c) => c.type == '광').length;
    int animal = cards.where((c) => c.type == '동물').length;
    int ribbon = cards.where((c) => c.type == '띠').length;
    int pi = cards.where((c) => c.type == '피').fold(0, (sum, c) {
      if (c.name.contains('쓰리피')) return sum + 3;
      if (c.name.contains('쌍피')) return sum + 2;
      return sum + 1;
    });

    if (gwang >= 3) score += (gwang == 3 ? 3 : (gwang == 4 ? 4 : 15));
    if (animal >= 5) score += animal - 4;
    if (ribbon >= 5) score += ribbon - 4;
    if (pi >= 10) score += pi - 9;
    if (_hasGodori(cards)) score += 5;
    if (animal >= 7) score *= 2;

    return score + goCount;
  }

  bool _hasGodori(List<GoStopCard> cards) {
    final godoriSet = {'1', '3', '8'};
    final months = cards
        .where((c) => c.type == '동물')
        .map((c) => c.month.toString())
        .toSet();
    return godoriSet.every(months.contains);
  }

  void declareGo() => goCount += 1;

  void declareStop() {
    winner = 'player$currentPlayer';
    gameOver = true;
  }

  String getResult() {
    if (!gameOver) return '게임 진행 중';
    final loser = winner == 'player1' ? 'player2' : 'player1';
    final winScore = calculateScore(winner!);
    final loseScore = calculateScore(loser);
    return "$winner 승리 ($winScore vs $loseScore)";
  }

  List<GoStopCard> getField() => field;
  List<GoStopCard> getHand(int playerNum) => hands['player$playerNum'] ?? [];
  List<GoStopCard> getCaptured(int playerNum) => captured['player$playerNum'] ?? [];
  int getCurrentPlayer() => currentPlayer;
  bool isGameOver() => gameOver;
  bool isAwaitingGoStop() => awaitingGoStop;
  String? getWinner() => winner;
}