import 'package:chat_app/language/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final Widget content;
  final Color bubbleColor;
  final bool isDeleted;
  const ChatBubble({
    super.key,
    required this.content,
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
      child: isDeleted ? Text(lanNotifier.translate('messageDeleted')) : content,
    );
  }
}
