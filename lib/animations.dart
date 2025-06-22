import 'package:flutter/material.dart';

class CustomAnimatedScale extends StatelessWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const CustomAnimatedScale({
    super.key,
    required this.child,
    required this.scale,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: scale),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class CustomAnimatedOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Duration duration;

  const CustomAnimatedOpacity({
    super.key,
    required this.child,
    required this.opacity,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: opacity),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class CustomAnimatedPosition extends StatelessWidget {
  final Widget child;
  final Offset begin;
  final Offset end;
  final Duration duration;
  final Curve curve;

  const CustomAnimatedPosition({
    super.key,
    required this.child,
    required this.begin,
    required this.end,
    required this.duration,
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
} 