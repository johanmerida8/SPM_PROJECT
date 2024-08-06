import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AudioPlaybackNotifier extends ValueNotifier<String?> {
  AudioPlaybackNotifier() : super(null);
}

class ChatBubble extends StatelessWidget {
  final String messageId;
  final String message;
  final String messageType;
  final Color bubbleColor;
  final bool isDeleted;
  final String reactions;
  final bool isSending;
  final AudioPlaybackNotifier audioPlaybackNotifier;
  final TextEditingController msgEditController;
  final ChatService chatService;
  final AudioPlayer audioPlayer;

  const ChatBubble({
    Key? key,
    required this.messageId,
    required this.message,
    required this.messageType,
    required this.bubbleColor,
    this.isDeleted = false,
    this.reactions = '',
    this.isSending = false,
    required this.audioPlaybackNotifier,
    required this.msgEditController,
    required this.chatService,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);

    Widget contentWidget;
    if (isSending) {
      contentWidget = const CircularProgressIndicator();
    } else if (isDeleted) {
      contentWidget = Text(lanNotifier.translate('messageDeleted'));
    } else {
      contentWidget = _buildContent(context);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bubbleColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          contentWidget,
          if (reactions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                reactions,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (messageType) {
      case 'image':
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoView(
                  imageProvider: NetworkImage(message),
                  minScale: PhotoViewComputedScale.contained,
                ),
              ),
            );
          },
          child: SizedBox(
            width: 200,
            height: 100,
            child: CachedNetworkImage(
              imageUrl: message,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
        );
      case 'document':
        return SizedBox(
          width: 100,
          height: 100,
          child: GestureDetector(
            onTap: () {
              final documentUrl = message;
              final encodedUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(documentUrl)}';
              Timer? pageLoadTimer;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Document Viewer'),
                    ),
                    body: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                      child: WebView(
                        initialUrl: encodedUrl,
                        javascriptMode: JavascriptMode.unrestricted,
                        onPageStarted: (String url) {
                          pageLoadTimer = Timer(const Duration(seconds: 10), () {
                            Navigator.pop(context);
                          });
                        },
                        onPageFinished: (String url) {
                          pageLoadTimer?.cancel();
                        },
                        onWebResourceError: (error) {
                          print('WebView error: ${error.description}');
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      case 'audio':
        return GestureDetector(
          onTap: () async {
            await _toggleAudio(message);
          },
          child: ValueListenableBuilder<String?>(
            valueListenable: audioPlaybackNotifier,
            builder: (context, playingUrl, child) {
              bool isPlaying = playingUrl == message;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlaying)
                    IconButton(
                      icon: const Icon(Icons.pause, color: Colors.grey, size: 24),
                      onPressed: () async {
                        await audioPlayer.pause();
                        audioPlaybackNotifier.value = null;
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.grey, size: 24),
                      onPressed: () async {
                        await _toggleAudio(message);
                      },
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.grey, size: 24),
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.stop();
                        audioPlaybackNotifier.value = null;
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      default:
        return Text(message);
    }
  }

  Future<void> _toggleAudio(String audioUrl) async {
    if (audioPlaybackNotifier.value == audioUrl) {
      await audioPlayer.pause();
      audioPlaybackNotifier.value = null;
    } else {
      await audioPlayer.stop();
      await audioPlayer.play(UrlSource(audioUrl));
      audioPlaybackNotifier.value = audioUrl;
    }
  }
}

