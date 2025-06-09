import 'dart:math';
import '../models/card_model.dart';
import '../data/card_data.dart';
import 'event_evaluator.dart';

class GoStop3PEngine {
  final List<GoStopCard> drawPile = [];
  final List<GoStopCard> field = [];
  final Map<String, List<GoStopCard>> hands = {
    'player1': [],
    'player2': [],
  };
  final Map<String, List<GoStopCard>> captured = {
    'player1': [],
    'player2': [],
  };
  int currentPlayer = 1;
  int goCount = 0;
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();

  GoStop3PEngine() {
    _initializeGame();
  }

  void _initializeGame() {
    final deck = List<GoStopCard>.from(goStopCards.where((c) => c.type != 'back'));
    deck.shuffle();

    field.addAll(deck.sublist(0, 8));
    hands['player1'] = deck.sublist(8, 18);
    hands['player2'] = deck.sublist(18, 28);
    drawPile.addAll(deck.sublist(28));

    currentPlayer = Random().nextBool() ? 1 : 2;
  }

  void playTurn(GoStopCard playedCard) {
    final playerKey = 'player$currentPlayer';
    hands[playerKey]!.remove(playedCard);
    bool gotTtak = EventEvaluator.isTtak(playedCard, field);

    _handlePlay(playerKey, playedCard);

    if (drawPile.isNotEmpty) {
      final drawn = drawPile.removeAt(0);
      bool gotChok = EventEvaluator.isChok(playedCard, drawn, field);
      _handlePlay(playerKey, drawn);
      if (gotChok) {
        _addBonusPi(playerKey, reason: "쪽");
      }
    }

    if (gotTtak) {
      _addBonusPi(playerKey, reason: "따닥");
    }

    if (eventEvaluator.isPuk(playedCard, field)) {
      _addBonusPi(playerKey, reason: "뻑");
      if (eventEvaluator.isTriplePuk()) {
        gameOver = true;
        winner = playerKey;
        return;
      }
    }

    if (_checkVictoryCondition(playerKey)) {
      gameOver = true;
      winner = playerKey;
    } else {
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    }
  }

  void _handlePlay(String playerKey, GoStopCard card) {
    final matches = field.where((c) => c.month == card.month).toList();

    if (matches.isEmpty) {
      field.add(card);
    } else if (matches.length == 1) {
      field.remove(matches.first);
      captured[playerKey]!.addAll([
      GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피1)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ),
      GoStopCard(
        id: 991,
        month: 0,
        type: '피',
        name: '보너스(쌍피2)',
        imageUrl: 'assets/cards/bonus_ssangpi2.png',
      ),card, matches.first]);
    } else if (matches.length == 2) {
      final chosen = matches[Random().nextInt(2)];
      field.remove(chosen);
      captured[playerKey]!.addAll([
      GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피1)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ),
      GoStopCard(
        id: 991,
        month: 0,
        type: '피',
        name: '보너스(쌍피2)',
        imageUrl: 'assets/cards/bonus_ssangpi2.png',
      ),card, chosen]);
    } else if (matches.length == 3) {
      field.removeWhere((c) => c.month == card.month);
      captured[playerKey]!.addAll([
      GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피1)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ),
      GoStopCard(
        id: 991,
        month: 0,
        type: '피',
        name: '보너스(쌍피2)',
        imageUrl: 'assets/cards/bonus_ssangpi2.png',
      ),card, ...matches]);
    }
  }

  void _addBonusPi(String playerKey, {required String reason}) {
    captured[playerKey]!.addAll([
      GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피1)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ),
      GoStopCard(
        id: 991,
        month: 0,
        type: '피',
        name: '보너스(쌍피2)',
        imageUrl: 'assets/cards/bonus_ssangpi2.png',
      ),
      GoStopCard(
        id: 990,
        month: 0,
        type: '피',
        name: '보너스(쌍피1)',
        imageUrl: 'assets/cards/bonus_ssangpi1.png',
      ),
      GoStopCard(
        id: 992,
        month: 0,
        type: '피',
        name: '보너스(쓰리피)',
        imageUrl: 'assets/cards/bonus_3pi.png',
      ),
    ]);
  }

  bool _checkVictoryCondition(String playerKey) {
    final score = calculateScore(playerKey);
    return score >= 3;
  }

  int calculateScore(String playerKey) {
    final cards = captured[playerKey]!;
    int score = 0;

    int gwang = cards.where((c) => c.type == '광').length;
    int animal = cards.where((c) => c.type == '동물').length;
    int ribbon = cards.where((c) => c.type == '띠').length;
    int pi = cards.where((c) => c.type == '피').fold(0, (sum, c) => sum + (c.name.contains('쌍') ? 2 : 1));

    if (gwang >= 3) score += (gwang == 3 ? 3 : (gwang == 4 ? 4 : 15));
    if (animal >= 5) score += animal - 4;
    if (ribbon >= 5) score += ribbon - 4;
    if (pi >= 10) score += pi - 9;

    if (_hasGodori(cards)) score += 5;
    if (animal >= 7) score *= 2; // 멍따

    return score + goCount;
  }

  bool _hasGodori(List<GoStopCard> cards) {
    final godoriSet = {'1', '3', '8'};
    final months = cards.where((c) => c.type == '동물').map((c) => c.month.toString()).toSet();
    return godoriSet.every(months.contains);
  }

  void declareGo() {
    goCount += 1;
  }

  void declareStop() {
    final playerKey = 'player$currentPlayer';
    gameOver = true;
    winner = playerKey;
  }

String getResult() {
  if (!gameOver) return '게임 진행 중';
  final loser = winner == 'player1' ? 'player2' : 'player1';
  final winScore = calculateScore(winner!);
  final loseScore = calculateScore(loser);
  return "$winner 승리 ($winScore vs $loseScore)";
}

  List<GoStopCard> getField() => field;
  List<GoStopCard> getHand(int playerNum) => hands['player\$playerNum'] ?? [];
  List<GoStopCard> getCaptured(int playerNum) => captured['player\$playerNum'] ?? [];
  int getCurrentPlayer() => currentPlayer;
  bool isGameOver() => gameOver;
  String? getWinner() => winner;
}