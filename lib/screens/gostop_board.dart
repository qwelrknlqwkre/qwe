import 'dart:math';

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../animations.dart';
import '../widgets/card_stack_widget.dart';
import '../widgets/card_deck_widget.dart';

class CardWidget extends StatelessWidget {
  final String imageUrl;
  final bool isFaceDown;
  final VoidCallback? onTap;
  final bool highlight;
  final double width;
  final double height;
  const CardWidget({super.key, required this.imageUrl, this.isFaceDown = false, this.onTap, this.highlight = false, this.width = 48, this.height = 72});
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: highlight ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            border: Border.all(color: highlight ? Colors.orange : Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: isFaceDown
              ? Container(color: Colors.red)
              : Image.asset(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// 피 점수 계산 (쌍피, 쓰리피, 보너스 포함)
int countPiScore(List<String> images) {
  int total = 0;
  for (final img in images) {
    if (img.contains('3pi')) {
      total += 3;
    } else if (img.contains('ssangpi')) {
      total += 2;
    } else {
      total += 1;
    }
  }
  return total;
}

Widget overlappedCardStack(List<String> images, {bool showBadge = false}) {
  final badgeCount = showBadge ? countPiScore(images) : null;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      for (int i = 0; i < images.length; i++)
        Positioned(
          left: i * 20.0, // 겹치는 정도 조절
          child: CardWidget(imageUrl: images[i]),
        ),
      if (showBadge && badgeCount != null && images.isNotEmpty)
        Positioned(
          left: (images.length - 1) * 20.0 + 32,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              '$badgeCount',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
    ],
  );
}

Widget capturedOverlapRow(Map<String, List<String>> captured) {
  final order = ['광', '끗', '띠', '피'];
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final type in order) ...[
        Column(
          children: [
            Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(
              width: (captured[type]?.length ?? 0) * 20.0 + 48,
              height: 72,
              child: overlappedCardStack(
                captured[type] ?? [],
                showBadge: type == '피',
              ),
            ),
          ],
        ),
        const SizedBox(width: 48),
      ]
    ],
  );
}

class _AnimatedDrawnCard extends StatefulWidget {
  final String backImage;
  final String frontImage;
  final Offset start;
  final Offset end;
  final bool flip;
  final VoidCallback? onEnd;
  final bool toCaptured;
  final Offset? capturedOffset;
  const _AnimatedDrawnCard({
    required this.backImage,
    required this.frontImage,
    required this.start,
    required this.end,
    this.flip = false,
    this.onEnd,
    this.toCaptured = false,
    this.capturedOffset,
  });
  @override
  State<_AnimatedDrawnCard> createState() => _AnimatedDrawnCardState();
}

class _AnimatedDrawnCardState extends State<_AnimatedDrawnCard> with TickerProviderStateMixin {
  late AnimationController moveCtrl;
  late AnimationController flipCtrl;
  late AnimationController scaleCtrl;
  late Animation<Offset> moveAnim;
  late Animation<double> flipAnim;
  late Animation<double> scaleAnim;
  bool movedToCaptured = false;

  @override
  void initState() {
    super.initState();
    moveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    moveAnim = Tween<Offset>(begin: widget.start, end: widget.end)
        .animate(CurvedAnimation(parent: moveCtrl, curve: Curves.easeInOut));
    flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: flipCtrl, curve: Curves.easeInOut));
    scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: scaleCtrl, curve: Curves.easeOut));

    // 애니메이션 시퀀스: 이동 → 뒤집기 → 스케일
    moveCtrl.forward().then((_) {
      if (widget.flip) {
        flipCtrl.forward().then((_) {
          scaleCtrl.forward().then((_) => _onAnimationEnd());
        });
      } else {
        scaleCtrl.forward().then((_) => _onAnimationEnd());
      }
    });
    
    moveCtrl.addListener(() => setState(() {}));
    flipCtrl.addListener(() => setState(() {}));
    scaleCtrl.addListener(() => setState(() {}));
  }

  void _onAnimationEnd() {
    if (!mounted) return;
    if (widget.toCaptured && widget.capturedOffset != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() { movedToCaptured = true; });
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onEnd?.call();
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onEnd?.call();
      });
    }
  }

  @override
  void dispose() {
    moveCtrl.dispose();
    flipCtrl.dispose();
    scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = movedToCaptured && widget.capturedOffset != null ? widget.capturedOffset! : moveAnim.value;
    final angle = flipAnim.value * pi;
    final isBack = angle < pi / 2;
    final scale = scaleAnim.value;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: SizedBox(
              width: 72,
              height: 96,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isBack ? 0 : pi),
                child: Image.asset(
                  isBack ? widget.backImage : widget.frontImage,
                  fit: BoxFit.contain,
                  key: ValueKey(isBack),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoStopBoard extends StatefulWidget {
  final List<GoStopCard> playerHand;
  final Map<String, List<String>> playerCaptured;
  final Map<String, List<String>> opponentCaptured;
  final List<GoStopCard> tableCards;
  final String drawnCard;
  final String deckBackImage;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final String statusLabel;
  final Function(int)? onCardTap;
  final String? effectBanner;
  final String? lastCapturedType;
  final int? lastCapturedIndex;
  final int opponentHandCount;
  final bool isGoStopPhase;
  final String? playedCard;
  final List<String>? capturedCards;
  final VoidCallback? onGo;
  final VoidCallback? onStop;
  final List<int> highlightHandIndexes;
  final CardDeckController? cardStackController;
  final int? drawPileCount;

  const GoStopBoard({
    super.key,
    required this.playerHand,
    required this.playerCaptured,
    required this.opponentCaptured,
    required this.tableCards,
    required this.drawnCard,
    required this.deckBackImage,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.statusLabel,
    this.onCardTap,
    this.effectBanner,
    this.lastCapturedType,
    this.lastCapturedIndex,
    required this.opponentHandCount,
    required this.isGoStopPhase,
    this.playedCard,
    this.capturedCards,
    this.onGo,
    this.onStop,
    required this.highlightHandIndexes,
    this.cardStackController,
    this.drawPileCount,
  });

  @override
  State<GoStopBoard> createState() => GoStopBoardState();
}

class GoStopBoardState extends State<GoStopBoard> with SingleTickerProviderStateMixin {
  bool showEffect = false;
  int? selectedHandIndex;
  bool isDealing = true;
  int dealStep = 0;
  final int totalDealCount = 28; // 2인 맞고: 10+10+8

  // 애니메이션 상태
  String? animDrawnFront;
  bool animatingDraw = false;
  Offset animStart = Offset.zero;
  Offset animEnd = Offset.zero;
  bool animToCaptured = false;
  Offset? animCapturedOffset;
  
  // 카드더미 위치를 저장할 GlobalKey
  final GlobalKey deckKey = GlobalKey();

  void playEatAnimation(int handIndex, int fieldIndex) {
    // 애니메이션 로직은 나중에 구현
  }

  void triggerDrawAnimation(String frontImage, {bool toCaptured = false, Offset? capturedOffset}) {
    if (mounted) {
      // 카드더미의 실제 위치 계산
      final RenderBox? deckRenderBox = deckKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? screenRenderBox = context.findRenderObject() as RenderBox?;
      
      if (deckRenderBox != null && screenRenderBox != null) {
        final deckPosition = deckRenderBox.localToGlobal(Offset.zero, ancestor: screenRenderBox);
        final deckSize = deckRenderBox.size;
        
        // 카드더미 중앙에서 시작
        final startX = deckPosition.dx + deckSize.width / 2 - 36; // 카드 너비의 절반
        final startY = deckPosition.dy + deckSize.height / 2 - 48; // 카드 높이의 절반
        
        // 필드 중앙으로 이동
        final screenSize = MediaQuery.of(context).size;
        final endX = screenSize.width / 2 - 36;
        final endY = screenSize.height / 2 - 48;
        
        setState(() {
          animDrawnFront = frontImage;
          animatingDraw = true;
          animStart = Offset(startX, startY);
          animEnd = Offset(endX, endY);
          animToCaptured = toCaptured;
          animCapturedOffset = capturedOffset;
        });
        
        // 애니메이션 완료 후 상태 초기화
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              animatingDraw = false;
              animDrawnFront = null;
            });
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _dealNextCard);
  }

  void _dealNextCard() {
    if (dealStep < totalDealCount) {
      setState(() => dealStep++);
      Future.delayed(const Duration(milliseconds: 80), _dealNextCard);
    } else {
      if (isDealing) {
      setState(() => isDealing = false);
      }
    }
  }

  void _onHandCardTap(int idx) {
    // 애니메이션 로직 제거 후 콜백만 직접 호출
    widget.onCardTap?.call(idx);
  }

  @override
  void didUpdateWidget(covariant GoStopBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectBanner != null && widget.effectBanner != oldWidget.effectBanner) {
      setState(() => showEffect = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => showEffect = false);
      });
    }
  }

  Widget _opponentHandZone() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.opponentHandCount, (i) =>
        CardWidget(imageUrl: widget.deckBackImage, isFaceDown: true)),
    );
  }

  Widget _fieldZone() {
    // 1. 카드를 월별로 그룹화
    final Map<int, List<GoStopCard>> monthlyCards = {};
    final List<GoStopCard> otherCards = [];

    for (final card in widget.tableCards) {
      if (card.month > 0) {
        monthlyCards.putIfAbsent(card.month, () => []).add(card);
      } else {
        otherCards.add(card);
      }
    }

    // 2. 표시할 위젯 리스트 생성 (단일 카드 또는 스택)
    final List<Widget> itemsToPlace = [];
    monthlyCards.forEach((month, cards) {
      if (cards.length == 1) {
        itemsToPlace.add(CardWidget(imageUrl: cards.first.imageUrl));
      } else {
        itemsToPlace.add(
          SizedBox(
            width: 48,
            height: 72 + (cards.length - 1) * 20.0,
            child: Stack(
              children: List.generate(cards.length, (i) {
                return Positioned(
                  left: 0,
                  top: i * 20.0,
                  child: CardWidget(imageUrl: cards[i].imageUrl),
                );
              }),
            ),
          ),
        );
      }
    });
    itemsToPlace.addAll(otherCards.map((card) => CardWidget(imageUrl: card.imageUrl)));

    // 3. 기존 레이아웃에 위젯 배치
    final List<Widget> fieldCardWidgets = [];
    final items = itemsToPlace.take(12).toList();

    if (items.isNotEmpty) fieldCardWidgets.add(Positioned(top: 20, left: 60, child: items[0]));
    if (items.length > 1) fieldCardWidgets.add(Positioned(top: 20, left: 120, child: items[1]));
    if (items.length > 2) fieldCardWidgets.add(Positioned(top: 20, right: 120, child: items[2]));
    if (items.length > 3) fieldCardWidgets.add(Positioned(top: 20, right: 60, child: items[3]));
    if (items.length > 4) fieldCardWidgets.add(Positioned(left: 0, top: 100, child: items[4]));
    if (items.length > 5) fieldCardWidgets.add(Positioned(left: 0, bottom: 80, child: items[5]));
    if (items.length > 6) fieldCardWidgets.add(Positioned(right: 0, top: 100, child: items[6]));
    if (items.length > 7) fieldCardWidgets.add(Positioned(right: 0, bottom: 80, child: items[7]));
    if (items.length > 8) fieldCardWidgets.add(Positioned(bottom: 0, left: 60, child: items[8]));
    if (items.length > 9) fieldCardWidgets.add(Positioned(bottom: 0, left: 120, child: items[9]));
    if (items.length > 10) fieldCardWidgets.add(Positioned(bottom: 0, right: 120, child: items[10]));
    if (items.length > 11) fieldCardWidgets.add(Positioned(bottom: 0, right: 60, child: items[11]));

    return Center(
      child: SizedBox(
        width: 420,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...fieldCardWidgets,
            Center(
              child: CardDeckWidget(
                key: deckKey,
                remainingCards: widget.drawPileCount ?? 0,
                cardBackImage: widget.deckBackImage,
                emptyDeckImage: widget.deckBackImage,
                controller: widget.cardStackController,
                showCountLabel: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myCapturedRow() {
    return capturedOverlapRow(widget.playerCaptured);
  }

  Widget _opponentCapturedRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24),
        Expanded(child: capturedOverlapRow(widget.opponentCaptured)),
        // 상대방 손패 개수 표시
        Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Text(
            '${widget.opponentHandCount}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> triggerDrawnCardAnimation({
    required String frontImage,
    required Offset start,
    required Offset end,
    bool toCaptured = false,
    Offset? capturedOffset,
    VoidCallback? onEnd,
  }) async {
    setState(() {
      animDrawnFront = frontImage;
      animatingDraw = true;
      animStart = start;
      animEnd = end;
      animToCaptured = toCaptured;
      animCapturedOffset = capturedOffset;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      animatingDraw = false;
      animDrawnFront = null;
    });
    if (onEnd != null) onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    if (isDealing) {
      // 카드더미에서 카드가 한 장씩 손패/필드로 이동하는 애니메이션
      return Scaffold(
        backgroundColor: const Color(0xFF2f4f2f),
        body: Stack(
          children: [
            // 카드더미
            Center(
              child: CardWidget(imageUrl: widget.deckBackImage, isFaceDown: true, width: 48, height: 72),
            ),
            // 이동 중인 카드(애니메이션)
            if (dealStep < totalDealCount)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                left: MediaQuery.of(context).size.width / 2 - 24 + (dealStep % 4 - 2) * 20,
                top: MediaQuery.of(context).size.height / 2 - 36 + (dealStep % 4 - 2) * 10,
                child: Opacity(
                  opacity: 1.0 - (dealStep % 4) * 0.2,
                  child: CardWidget(imageUrl: widget.deckBackImage, isFaceDown: true, width: 48, height: 72),
                ),
              ),
            // 분배 텍스트
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text('카드 분배 중...', style: TextStyle(color: Colors.white, fontSize: 28)),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF2f4f2f),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단: 상대방 정보 + 손패(뒷면) + 상대방 획득카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(height: 4),
                          Text(widget.opponentName, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _opponentHandZone()),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text('${widget.opponentScore}점',
                              key: ValueKey(widget.opponentScore),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _opponentCapturedRow(),
                // 중앙: 필드카드(8장 십자) + 카드더미
                Expanded(
                  flex: isTablet ? 5 : 4,
                  child: _fieldZone(),
                ),
                // 하단: 내 획득 카드(분류, 손패 위) + 내 손패
                Container(
                  color: Colors.black.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      _myCapturedRow(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 내 손패 렌더링 부분: 애니메이션 없이 기존대로 복원
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (int i = 0; i < widget.playerHand.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.topCenter,
                                        children: [
                                          // 먹을 수 있는 카드면 카드 위에 화살표 표시
                                          if (widget.highlightHandIndexes.contains(i))
                                            Positioned(
                                              top: -24,
                                              child: Icon(Icons.arrow_drop_down, color: Colors.orange, size: 40),
                                            ),
                                          GestureDetector(
                                            onTap: () => _onHandCardTap(i),
                                            child: CardWidget(
                                              imageUrl: widget.playerHand[i].imageUrl,
                                              width: 96,
                                              height: 144,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // 점수/상태
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text('${widget.playerScore}점',
                                  key: ValueKey(widget.playerScore),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  key: ValueKey(widget.statusLabel),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(widget.statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 효과 배너 애니메이션
            if (widget.effectBanner != null)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: showEffect ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.yellow,
                      child: Text(widget.effectBanner!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            // 하단: GO/STOP 버튼
            if (widget.isGoStopPhase)
              Positioned(
                right: 32,
                bottom: 32,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: widget.onGo,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('GO'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: widget.onStop,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('STOP'),
                    ),
                  ],
                ),
              ),
            // 카드더미에서 바닥으로 이동/뒤집기/먹기 애니메이션
            if (animatingDraw && animDrawnFront != null)
              _AnimatedDrawnCard(
                backImage: widget.deckBackImage,
                frontImage: animDrawnFront!,
                start: animStart,
                end: animEnd,
                flip: true,
                toCaptured: animToCaptured,
                capturedOffset: animCapturedOffset,
              ),
          ],
        ),
      ),
    );
  }
}