import 'dart:math';
import '../models/card_model.dart';
import 'event_evaluator.dart';
import 'deck_manager.dart';

// 게임의 현재 단계를 나타내는 열거형
enum TurnPhase {
  playingCard, // 손패 내는 중
  flippingCard, // 카드 더미 뒤집는 중
  choosingMatch, // 짝 선택 중 (따닥)
  turnEnd, // 턴 종료 및 정산
}

class MatgoEngine {
  final DeckManager deckManager;
  int currentPlayer = 1;
  int goCount = 0;
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();
  bool awaitingGoStop = false;

  // 턴 진행 관련 상태
  TurnPhase currentPhase = TurnPhase.playingCard;
  GoStopCard? playedCard; // 이번 턴에 낸 카드
  List<GoStopCard> pendingCaptured = []; // 이번 턴에 획득할 예정인 카드들
  List<GoStopCard> choices = []; // 따닥 발생 시 선택할 카드들

  MatgoEngine(this.deckManager);

  void reset() {
    deckManager.reset();
    currentPlayer = 1;
    goCount = 0;
    winner = null;
    gameOver = false;
    awaitingGoStop = false;
    currentPhase = TurnPhase.playingCard;
    playedCard = null;
    pendingCaptured.clear();
    choices.clear();
  }

  List<GoStopCard> getHand(int playerNum) => deckManager.getPlayerHand(playerNum - 1);
  List<GoStopCard> getField() => deckManager.getFieldCards();
  List<GoStopCard> getCaptured(int playerNum) => deckManager.capturedCards[playerNum - 1] ?? [];
  int get drawPileCount => deckManager.drawPile.length;

  // 1단계: 플레이어가 손에서 카드를 냄
  void playCard(GoStopCard card) {
    if (currentPhase != TurnPhase.playingCard) return;

    final playerIdx = currentPlayer - 1;
    deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
    playedCard = card;

    final fieldMatches = getField().where((c) => c.month == card.month).toList();
    
    // 먹을 카드가 있으면 임시 목록에 추가
    if (fieldMatches.length == 1) {
      pendingCaptured.addAll([card, fieldMatches.first]);
      deckManager.fieldCards.remove(fieldMatches.first);
    } else if (fieldMatches.length == 2) {
      // '따닥'은 아니지만, 일단 낸 카드는 임시 목록에 추가
      pendingCaptured.add(card);
    } else if (fieldMatches.length == 3) {
      // '싹쓸이'의 경우, 낸 카드와 바닥 카드 모두 임시 목록에
      pendingCaptured.addAll([card, ...fieldMatches]);
      deckManager.fieldCards.removeWhere((c) => c.month == card.month);
    } else {
      // 먹을 카드가 없으면 바닥에 내려놓기만 함
      deckManager.fieldCards.add(card);
    }

    currentPhase = TurnPhase.flippingCard;
  }
  
  // 2단계: 카드 더미에서 카드를 뒤집음
  void flipFromDeck() {
    if (currentPhase != TurnPhase.flippingCard) return;
    if (deckManager.drawPile.isEmpty) {
      _endTurn();
      return;
    }

    GoStopCard drawnCard = deckManager.drawPile.removeAt(0);

    // 보너스 카드 처리
    if (drawnCard.isBonus) {
        pendingCaptured.add(drawnCard);
        // 보너스 카드를 뒤집었으면 한 장 더 뒤집음
        flipFromDeck(); 
        return;
    }
    
    final fieldMatches = getField().where((c) => c.month == drawnCard.month).toList();

    // 뻑 (Ppeok) 체크
    if (playedCard != null && playedCard!.month == drawnCard.month && getField().any((c) => c.month == drawnCard.month)) {
      deckManager.fieldCards.add(drawnCard);
      // 먹으려던 카드들도 다시 바닥으로
      if (pendingCaptured.isNotEmpty) {
        deckManager.fieldCards.addAll(pendingCaptured);
        pendingCaptured.clear();
      }
       _endTurn();
       return;
    }
    
    // 따닥 (Choice)
    if (fieldMatches.length == 2) {
      choices = fieldMatches;
      pendingCaptured.add(drawnCard);
      currentPhase = TurnPhase.choosingMatch;
      return;
    }

    // 일반 먹기
    if (fieldMatches.length == 1) {
      pendingCaptured.addAll([drawnCard, fieldMatches.first]);
      deckManager.fieldCards.remove(fieldMatches.first);
    } else {
      // 못 먹는 경우
      deckManager.fieldCards.add(drawnCard);
    }

    _endTurn();
  }

  // 2-1단계: '따닥'에서 카드 선택
  void chooseMatch(GoStopCard chosenCard) {
    if (currentPhase != TurnPhase.choosingMatch) return;
    
    final otherCard = choices.firstWhere((c) => c.id != chosenCard.id);
    pendingCaptured.add(chosenCard); // 선택한 카드 획득
    deckManager.fieldCards.remove(chosenCard); // 바닥에서 제거
    // 선택하지 않은 카드는 바닥에 그대로 둠
    
    choices.clear();
    _endTurn();
  }

  // 3단계: 턴 종료 및 정산
  void _endTurn() {
    final playerIdx = currentPlayer - 1;
    if (pendingCaptured.isNotEmpty) {
      deckManager.capturedCards[playerIdx] = [...deckManager.capturedCards[playerIdx]!, ...pendingCaptured];
    }
    
    // 상태 초기화
    pendingCaptured.clear();
    playedCard = null;

    if (_checkVictoryCondition()) {
      awaitingGoStop = true;
      currentPhase = TurnPhase.turnEnd;
      // 턴을 넘기지 않고 '고/스톱' 결정을 기다림
      return;
    }
    
    // 다음 플레이어로 턴 넘김
    currentPlayer = (currentPlayer % 2) + 1;
    currentPhase = TurnPhase.playingCard;
  }
  
  bool _checkVictoryCondition() {
    final score = calculateScore(currentPlayer);
    // 맞고는 3점부터
    return score >= 3; 
  }

  void declareGo() {
    if (!awaitingGoStop) return;
    goCount++;
    awaitingGoStop = false;
    // '고'를 했으므로 턴을 넘기지 않음
    currentPhase = TurnPhase.playingCard;
  }

  void declareStop() {
    if (!awaitingGoStop) return;
    winner = 'player$currentPlayer';
    gameOver = true;
    currentPhase = TurnPhase.turnEnd;
  }

  // 기존 로직들 (일부 수정 필요)
  void _stealOpponentPi(int playerIdx) {
    // ... 이 로직은 pendingCaptured에 추가하는 방식으로 수정되어야 함
  }
  
  int calculateScore(int playerNum) {
    // ... 기존 점수 계산 로직
    return 0; // 임시
  }
  
  String getResult() {
    // ... 기존 결과 표시 로직
    return ""; // 임시
  }
  
  bool isGameOver() => gameOver;

  // ... 기타 헬퍼 메서드들
}