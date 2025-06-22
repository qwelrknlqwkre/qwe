import 'package:flutter/material.dart';
import 'dart:math';

class CardStackController {
  VoidCallback? _flip;
  void flipCard() => _flip?.call();
}

class CardStackWidget extends StatefulWidget {
  final CardStackController controller;
  final String cardBackImage;
  final String cardFrontImage;
  final VoidCallback? onFlipComplete;
  final int stackCount;
  const CardStackWidget({
    super.key,
    required this.controller,
    required this.cardBackImage,
    required this.cardFrontImage,
    this.onFlipComplete,
    this.stackCount = 12,
  });
  @override
  State<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUpAnim;
  late Animation<double> _flipAnim;
  late Animation<double> _scaleAnim;
  bool isFlipping = false;
  bool showFront = false;

  @override
  void initState() {
    super.initState();
    widget.controller._flip = _startFlip;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _moveUpAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -60).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: -60, end: 0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
    ]).animate(_controller);
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.linear)),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)));
    _controller.addListener(() {
      if (_flipAnim.value > pi / 2 && !showFront) {
        setState(() { showFront = true; });
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() { isFlipping = false; showFront = false; });
        widget.onFlipComplete?.call();
      }
    });
  }

  void _startFlip() {
    if (isFlipping) return;
    setState(() { isFlipping = true; showFront = false; });
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 카드 스택(뒷면)
            for (int i = 0; i < widget.stackCount - (isFlipping ? 1 : 0); i++)
              Positioned(
                top: i * 2.0,
                child: Image.asset(widget.cardBackImage, width: 72, height: 108, fit: BoxFit.contain),
              ),
            // 애니메이션 카드
            if (isFlipping)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final y = _moveUpAnim.value;
                  final scale = _scaleAnim.value;
                  final angle = _flipAnim.value;
                  final isBack = angle < pi / 2 && !showFront;
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          isBack ? widget.cardBackImage : widget.cardFrontImage,
                          width: 72,
                          height: 108,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
} 