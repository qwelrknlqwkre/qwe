import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// 1. Card Data Model
class CardModel {
  final int id;
  final int month;
  final String type; // '광', '띠', '오', '피'
  final bool isBonus;
  final String imageAsset;

  CardModel({
    required this.id,
    required this.month,
    required this.type,
    this.isBonus = false,
    required this.imageAsset,
  });
}

// 2. Deck Initialization
class DeckManager with ChangeNotifier {
  final List<CardModel> fullDeck = [];
  final List<CardModel> player1Hand = [];
  final List<CardModel> player2Hand = [];
  final List<CardModel> tableCards = [];
  final List<CardModel> deckPile = [];

  // Animation helpers
  List<Offset> cardPositions = [];
  List<double> cardRotations = [];
  List<int> cardZOrders = [];
  bool isShuffling = false;
  bool isDealing = false;

  DeckManager() {
    _initDeck();
  }

  void _initDeck() {
    fullDeck.clear();
    // 48장 + (옵션) 보너스 피 2장
    int id = 1;
    for (int month = 1; month <= 12; month++) {
      // 실제 화투 카드 분포에 맞게 추가
      // 예시: 광 1장, 띠 1장, 오 1장, 피 2장 (월별로 다름, 실제 게임에 맞게 조정 필요)
      fullDeck.add(CardModel(id: id++, month: month, type: '광', imageAsset: 'assets/cards/${month}_gwang.png'));
      fullDeck.add(CardModel(id: id++, month: month, type: '띠', imageAsset: 'assets/cards/${month}_tti.png'));
      fullDeck.add(CardModel(id: id++, month: month, type: '오', imageAsset: 'assets/cards/${month}_oh.png'));
      fullDeck.add(CardModel(id: id++, month: month, type: '피', imageAsset: 'assets/cards/${month}_pi1.png'));
      fullDeck.add(CardModel(id: id++, month: month, type: '피', imageAsset: 'assets/cards/${month}_pi2.png'));
    }
    // 보너스 피 카드 (옵션)
    fullDeck.add(CardModel(id: id++, month: 0, type: '피', isBonus: true, imageAsset: 'assets/cards/bonus_ssangpi.png'));
    fullDeck.add(CardModel(id: id++, month: 0, type: '피', isBonus: true, imageAsset: 'assets/cards/bonus_3pi.png'));
    resetState();
  }

  void resetState() {
    player1Hand.clear();
    player2Hand.clear();
    tableCards.clear();
    deckPile.clear();
    cardPositions = List.generate(fullDeck.length, (i) => Offset.zero);
    cardRotations = List.generate(fullDeck.length, (i) => 0.0);
    cardZOrders = List.generate(fullDeck.length, (i) => i);
    isShuffling = false;
    isDealing = false;
    notifyListeners();
  }

  // 3. Shuffle (Fisher-Yates)
  void shuffleDeck() {
    isShuffling = true;
    final random = Random();
    for (int i = fullDeck.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      final temp = fullDeck[i];
      fullDeck[i] = fullDeck[j];
      fullDeck[j] = temp;
    }
    // Shuffle animation helpers
    cardZOrders.shuffle(random);
    for (int i = 0; i < fullDeck.length; i++) {
      cardRotations[i] = (random.nextDouble() - 0.5) * 0.4; // -0.2 ~ 0.2 rad
      cardPositions[i] = Offset(
        (random.nextDouble() - 0.5) * 16,
        (random.nextDouble() - 0.5) * 16,
      );
    }
    notifyListeners();
    isShuffling = false;
  }

  // 4. Card Distribution Logic
  void dealCards() {
    player1Hand.clear();
    player2Hand.clear();
    tableCards.clear();
    deckPile.clear();
    // 분배 순서: 10장씩, 8장, 나머지
    for (int i = 0; i < 10; i++) {
      player1Hand.add(fullDeck[i]);
      player2Hand.add(fullDeck[i + 10]);
    }
    for (int i = 20; i < 28; i++) {
      tableCards.add(fullDeck[i]);
    }
    for (int i = 28; i < fullDeck.length; i++) {
      deckPile.add(fullDeck[i]);
    }
    notifyListeners();
  }

  // 5. Async Deal Animation
  Future<void> animateDeal({Duration delay = const Duration(milliseconds: 120)}) async {
    isDealing = true;
    player1Hand.clear();
    player2Hand.clear();
    tableCards.clear();
    deckPile.clear();
    notifyListeners();
    // 실제 분배 순서: 1장씩 번갈아 10장, 8장, 나머지
    for (int i = 0; i < 10; i++) {
      player1Hand.add(fullDeck[i]);
      notifyListeners();
      await Future.delayed(delay);
      player2Hand.add(fullDeck[i + 10]);
      notifyListeners();
      await Future.delayed(delay);
    }
    for (int i = 20; i < 28; i++) {
      tableCards.add(fullDeck[i]);
      notifyListeners();
      await Future.delayed(delay);
    }
    for (int i = 28; i < fullDeck.length; i++) {
      deckPile.add(fullDeck[i]);
    }
    isDealing = false;
    notifyListeners();
  }
} 