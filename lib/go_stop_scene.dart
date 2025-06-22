import 'dart:math';
import 'package:flutter/material.dart';

// 더미 카드 이미지 경로 (없으면 갈색 박스)
const dummyCardImages = [
  'assets/cards/1_gwang.png',
  'assets/cards/2_pi1.png',
  'assets/cards/3_pi2.png',
  'assets/cards/4_ribbon.png',
  'assets/cards/5_animal.png',
  'assets/cards/6_pi1.png',
  'assets/cards/7_pi2.png',
  'assets/cards/8_gwang.png',
  'assets/cards/9_pi1.png',
  'assets/cards/10_pi2.png',
];

Color kBgStart = const Color(0xFF9CCC65);
Color kBgEnd = const Color(0xFF7CB342);
Color kMoneyYellow = const Color(0xFFFFEB3B);
Color kScoreGray = Colors.black.withOpacity(0.5);

class GoStopScene extends StatefulWidget {
  const GoStopScene({super.key});
  @override
  State<GoStopScene> createState() => _GoStopSceneState();
}

class _GoStopSceneState extends State<GoStopScene> with TickerProviderStateMixin {
  // 더미 데이터
  final List<String> myHand = List.generate(10, (i) => dummyCardImages[i % dummyCardImages.length]);
  final List<int> highlightIndexes = [2, 3, 5, 8];
  final List<String> fieldCards = [
    dummyCardImages[0], dummyCardImages[1], dummyCardImages[2], dummyCardImages[3],
    dummyCardImages[4], dummyCardImages[5], dummyCardImages[6], dummyCardImages[7]
  ];
  final String lastPlayedCard = dummyCardImages[3];
  final int myScore = 23;
  final int myMoney = 317570000;
  final int myMoneyPlus = 106320000;
  final int oppMoney = 5920800000;
  final String oppName = '이라이라';
  final int oppLevel = 86;
  final int myLevel = 53;
  final int oppHearts = 4;
  final int goStopMultiplier = 2;
  final bool isGoStop = true;
  final bool isAutoPlay = false;

  late AnimationController _goStopController;
  late Animation<double> _goStopAnim;

  @override
  void initState() {
    super.initState();
    _goStopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _goStopAnim = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _goStopController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _goStopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material 3 + 커스텀 팔레트
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBgStart,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            // 배경 그라디언트
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBgStart, kBgEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // 자동치기 버튼
            Positioned(
              right: 24, bottom: 24,
              child: Semantics(
                label: '자동 치기',
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.refresh, color: Colors.green[900], size: 36),
                  ),
                ),
              ),
            ),
            // 상단 UI
            Positioned(
              left: 16, top: 16,
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: kMoneyYellow, size: 28),
                  const SizedBox(width: 4),
                  Semantics(
                    label: '점수 100만냥',
                    child: Text('점100만냥', style: TextStyle(
                      color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 18,
                    )),
                  ),
                ],
              ),
            ),
            // 우측 상단 프로필 카드
            Positioned(
              right: 16, top: 16,
              child: _OpponentProfile(
                name: oppName,
                level: oppLevel,
                money: oppMoney,
                hearts: oppHearts,
              ),
            ),
            // GO/STOP 배너
            if (isGoStop)
              Positioned(
                right: 24, top: 120,
                child: AnimatedBuilder(
                  animation: _goStopAnim,
                  builder: (context, child) {
                    return Container(
                      width: 80, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -_goStopAnim.value),
                            child: Icon(Icons.arrow_upward, color: Colors.red, size: 36),
                          ),
                          Transform.translate(
                            offset: Offset(0, _goStopAnim.value),
                            child: Icon(Icons.arrow_downward, color: Colors.blue, size: 36),
                          ),
                          const SizedBox(height: 8),
                          Text('x$goStopMultiplier', style: TextStyle(
                            color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 28,
                          )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // 이모티콘/나가기 버튼
            Positioned(
              right: 24, top: 260,
              child: Row(
                children: [
                  _RoundButton(text: '이모티콘', onTap: () {}),
                  const SizedBox(width: 12),
                  _RoundButton(text: '나가기', onTap: () {}),
                ],
              ),
            ),
            // 센터 필드 (카드 4x3 그리드)
            Center(
              child: SizedBox(
                width: 360, height: 320,
                child: Stack(
                  children: [
                    // 4x3 그리드 배경 (투명)
                    for (int i = 0; i < 12; i++)
                      Positioned(
                        left: (i % 4) * 90.0,
                        top: (i ~/ 4) * 106.0,
                        child: SizedBox(width: 72, height: 96),
                      ),
                    // 실제 놓인 카드만 배치
                    ..._buildFieldCards(),
                    // 더미(뒷면) 카드 (중앙)
                    Positioned(
                      left: 90.0 * 1.5, top: 106.0 * 1,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: _CardImage(
                          image: 'assets/cards/back.png',
                          width: 72, height: 96,
                          isBack: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 내 점수 라벨
            Positioned(
              bottom: 180, left: 0, right: 0,
              child: Center(
                child: Semantics(
                  label: '내 점수 $myScore점',
                  child: Container(
                    width: 120, height: 32,
                    decoration: BoxDecoration(
                      color: kScoreGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text('$myScore점', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20,
                    )),
                  ),
                ),
              ),
            ),
            // 내 먹은 카드 카테고리별 4섹션 (Wrap)
            Positioned(
              bottom: 220, left: 0, right: 0,
              child: Center(
                child: Wrap(
                  spacing: 12,
                  children: [
                    _CapturedCategory(label: '광', count: 1),
                    _CapturedCategory(label: '띠', count: 2),
                    _CapturedCategory(label: '동물', count: 1),
                    _CapturedCategory(label: '피', count: 7),
                  ],
                ),
              ),
            ),
            // 내 손패 (하단)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Semantics(
                label: '내 손패',
                child: Container(
                  color: Colors.transparent,
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    itemCount: myHand.length,
                    separatorBuilder: (_, __) => const SizedBox(width: -12),
                    itemBuilder: (context, i) {
                      final isHighlight = highlightIndexes.contains(i);
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          if (isHighlight)
                            Positioned(
                              top: -18,
                              child: Icon(Icons.arrow_drop_down, color: Colors.blue, size: 40, semanticLabel: '먹을 수 있는 카드'),
                            ),
                          _CardImage(image: myHand[i], width: 72, height: 96),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 필드 카드 배치 (중앙 4x3 그리드 중 실제 카드만)
  List<Widget> _buildFieldCards() {
    // 예시: 8장만 배치, 랜덤 위치
    final positions = [
      Offset(0, 0), Offset(90, 0), Offset(180, 0), Offset(270, 0),
      Offset(0, 106), Offset(90, 106), Offset(180, 106), Offset(270, 106),
    ];
    return List.generate(fieldCards.length, (i) {
      final isLast = fieldCards[i] == lastPlayedCard;
      return Positioned(
        left: positions[i].dx,
        top: positions[i].dy,
        child: _CardImage(
          image: fieldCards[i],
          width: 72,
          height: 96,
          isLast: isLast,
        ),
      );
    });
  }
}

// 카드 이미지 위젯 (플레이스홀더 지원, 마지막 낸 카드 강조)
class _CardImage extends StatelessWidget {
  final String image;
  final double width, height;
  final bool isBack;
  final bool isLast;
  const _CardImage({
    required this.image,
    this.width = 72,
    this.height = 96,
    this.isBack = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Image.asset(
      image,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Colors.brown,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    if (isLast) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange[700]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: card,
      );
    }
    return card;
  }
}

// 상대방 프로필 카드
class _OpponentProfile extends StatelessWidget {
  final String name;
  final int level;
  final int money;
  final int hearts;
  const _OpponentProfile({
    required this.name,
    required this.level,
    required this.money,
    required this.hearts,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name 프로필, 레벨 $level, 보유머니 $money',
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: Colors.green[200], child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lv.$level', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.monetization_on, color: kMoneyYellow, size: 20),
                const SizedBox(width: 4),
                Text('${_moneyStr(money)}', style: TextStyle(
                  color: kMoneyYellow, fontWeight: FontWeight.bold, fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                )),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(4, (i) => Icon(
                Icons.favorite,
                color: i < hearts ? Colors.red : Colors.grey[300],
                size: 18,
                semanticLabel: i < hearts ? '하트' : '빈 하트',
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// 둥근 버튼
class _RoundButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _RoundButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// 먹은 카드 카테고리
class _CapturedCategory extends StatelessWidget {
  final String label;
  final int count;
  const _CapturedCategory({required this.label, required this.count});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $count장',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 4),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

// 머니 포맷
String _moneyStr(int money) {
  if (money >= 100000000) {
    return '${(money / 100000000).floor()}억${((money % 100000000) / 10000).floor()}만냥';
  } else if (money >= 10000) {
    return '${(money / 10000).floor()}만냥';
  }
  return '$money냥';
} 