import 'package:flutter/material.dart';
import '../utils/matgo_engine.dart';
import '../models/card_model.dart';
import '../screens/gostop_board.dart';
import '../utils/deck_manager.dart';
import '../widgets/card_deck_widget.dart';

class GamePage extends StatefulWidget {
  final String mode;
  const GamePage({required this.mode, super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late MatgoEngine engine;
  late DeckManager deckManager;
  final GlobalKey<GoStopBoardState> boardKey = GlobalKey<GoStopBoardState>();
  final CardDeckController cardDeckController = CardDeckController();

  @override
  void initState() {
    super.initState();
    deckManager = DeckManager(
      playerCount: widget.mode == 'matgo' ? 2 : 3,
      isMatgo: widget.mode == 'matgo',
    );
    engine = MatgoEngine(deckManager);
    _runAiTurnIfNeeded();
  }

  // 1단계: 손패 카드 탭 처리
  void onCardTap(GoStopCard card) {
    if (engine.currentPlayer != 1 || engine.currentPhase != TurnPhase.playingCard) return;

    setState(() {
      engine.playCard(card);
    });

    // 2단계: 카드 더미 뒤집기 (딜레이 후 자동 실행)
    Future.delayed(const Duration(milliseconds: 500), _flipCardFromDeck);
  }

  // 2단계: 카드 더미 뒤집기 로직
  Future<void> _flipCardFromDeck() async {
    if (engine.currentPhase != TurnPhase.flippingCard) return;

    // 애니메이션 트리거 로직 (UI와 연동 필요)
    // final drawnCard = engine.deckManager.drawPile.first;
    // boardKey.currentState?.triggerDrawAnimation(drawnCard.imageUrl);
    
    setState(() {
      engine.flipFromDeck();
    });

    // '따닥' 발생 시 사용자 선택 대화상자 표시
    if (engine.currentPhase == TurnPhase.choosingMatch) {
      await _showMatchChoiceDialog();
    }
    
    // 턴 종료 후 AI 턴 확인
    if (engine.currentPhase == TurnPhase.playingCard) {
      _runAiTurnIfNeeded();
    }
  }

  // '따닥' 선택 대화상자
  Future<void> _showMatchChoiceDialog() async {
    final chosenCard = await showDialog<GoStopCard>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('먹을 카드를 선택하세요'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: engine.choices
                .map((card) => GestureDetector(
                      onTap: () => Navigator.pop(context, card),
                      child: Image.asset(card.imageUrl, width: 80),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (chosenCard != null) {
      setState(() => engine.chooseMatch(chosenCard));
      if (engine.currentPhase == TurnPhase.playingCard) {
        _runAiTurnIfNeeded();
      }
    }
  }

  // AI 턴 실행 로직
  Future<void> _runAiTurnIfNeeded() async {
    if (engine.isGameOver() || engine.currentPlayer != 2) return;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final aiHand = engine.getHand(2);
    if (aiHand.isNotEmpty) {
      final aiCardToPlay = aiHand.first;
      setState(() => engine.playCard(aiCardToPlay));

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() => engine.flipFromDeck());

      if (engine.currentPhase == TurnPhase.choosingMatch) {
        setState(() => engine.chooseMatch(engine.choices.first));
      }
      
      if (engine.awaitingGoStop) {
        if (engine.calculateScore(2) >= 3) {
          setState(() => engine.declareGo());
          _runAiTurnIfNeeded();
        } else {
          setState(() => engine.declareStop());
          _showGameOverDialog();
        }
      } else if (engine.currentPhase == TurnPhase.playingCard) {
        // 턴이 플레이어에게 돌아왔는지 확인
        _runAiTurnIfNeeded();
      }
    }
  }

  void _showGameOverDialog() {
    if (!engine.isGameOver()) return;
    final result = engine.getResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('게임 종료'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => engine.reset());
              _runAiTurnIfNeeded();
            },
            child: const Text('다시 시작'),
          ),
        ],
      ),
    );
  }

  // 획득한 카드를 UI에 표시하기 위해 타입별로 그룹화하는 헬퍼 함수
  Map<String, List<String>> groupCapturedByType(List<dynamic> cards) {
    final Map<String, List<String>> grouped = {};
    for (final card in cards) {
      final type = card.type ?? '기타';
      grouped.putIfAbsent(type, () => <String>[]);
      grouped[type]!.add(card.imageUrl.toString());
    }
    return grouped.map((k, v) => MapEntry(k, v.map((e) => e.toString()).toList()));
  }

  // 안전하게 isAwaitingGoStop 호출
  bool getIsAwaitingGoStop() {
    return engine.awaitingGoStop;
  }

  @override
  Widget build(BuildContext context) {
    final List<GoStopCard> playerHand = List<GoStopCard>.from(engine.getHand(1));
    final List<GoStopCard> opponentHand = List<GoStopCard>.from(engine.getHand(2));
    final List<GoStopCard> fieldCards = List<GoStopCard>.from(engine.getField());
    final int drawPileCount = engine.drawPileCount;

    // 먹을 수 있는 카드 인덱스 계산
    final fieldMonths = fieldCards.map((c) => c.month).where((m) => m > 0).toSet();
    final highlightHandIndexes = <int>[];
    for (int i = 0; i < playerHand.length; i++) {
      final card = playerHand[i];
      if (card.isBonus || (card.month > 0 && fieldMonths.contains(card.month))) {
        highlightHandIndexes.add(i);
      }
    }
    
    print('내 손패 개수: ${playerHand.length}');
    print('상대 손패 개수: ${opponentHand.length}');
    print('필드 카드 개수: ${fieldCards.length}');
    print('카드더미 남은 장수: ${drawPileCount}');
    print('[DEBUG] engine.getHand(1) length:  [36m${engine.getHand(1).length} [0m');
    print('[DEBUG] engine.getHand(2) length:  [36m${engine.getHand(2).length} [0m');
    
    return GoStopBoard(
      key: boardKey,
      playerHand: playerHand,
      playerCaptured: groupCapturedByType(engine.getCaptured(1)),
      opponentCaptured: groupCapturedByType(engine.getCaptured(2)),
      tableCards: fieldCards,
      drawnCard: '', // 이 속성은 더 이상 사용하지 않음
      deckBackImage: 'assets/cards/back.png',
      opponentName: '상대방',
      playerScore: engine.calculateScore(1),
      opponentScore: engine.calculateScore(2),
      statusLabel: '게임 진행 중', // 상태 라벨도 엔진 상태에 따라 변경 필요
      opponentHandCount: opponentHand.length,
      isGoStopPhase: engine.awaitingGoStop && engine.currentPlayer == 1,
      highlightHandIndexes: highlightHandIndexes,
      onCardTap: (index) {
        if (index < playerHand.length) {
          onCardTap(playerHand[index]);
        }
      },
      cardStackController: cardDeckController,
      drawPileCount: drawPileCount,
    );
  }
}

// MatgoEngine 에 isGameOver() 메서드 추가 필요
extension MatgoEngineExtension on MatgoEngine {
  bool isGameOver() => gameOver;
}