import 'package:chat_app/components/delayed_animation.dart';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {

   //boolean to check if the user is typing
  final bool isTyping;

  const TypingIndicator({
    super.key,
    required this.isTyping,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin{

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isTyping ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildDot(index)),
    ) : Container();
  }

  Widget _buildDot(int index) {
    return DelayedAnimation(
      delay: index * 100,
      child: Transform.translate(
        offset: Offset(0, -5 * _animation.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}