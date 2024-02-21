import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String msg;
  final Color bubbleColor;
  const ChatBubble({
    super.key,
    required this.msg,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bubbleColor,
      ),
      child: Text(
        msg,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}