import 'package:chat_app/language/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String msg;
  final Color bubbleColor;
  final bool isDeleted;
  const ChatBubble({
    super.key,
    required this.msg,
    required this.bubbleColor,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bubbleColor,
      ),
      child: Text(
        isDeleted ? lanNotifier.translate('messageDeleted') : msg,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}
