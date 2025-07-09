import 'package:flutter/material.dart';
import '../core/services/icon_service.dart';

class AnimatedInfinity extends StatefulWidget {
  final Color color;
  final double size;
  const AnimatedInfinity({super.key, required this.color, required this.size});

  @override
  State<AnimatedInfinity> createState() => _AnimatedInfinityState();
}

class _AnimatedInfinityState extends State<AnimatedInfinity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Image.asset(
        IconService.iconBlue,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}