import 'package:audioplayers/audioplayers.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/model/reactions.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessageOptions extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentSnapshot document;
  final TextEditingController msgEditController;
  final String receiverUserID;
  final ChatService chatService;
  final List<Reaction> reactions;
  final bool Function(Map<String, dynamic>) hasReactions;
  final Future<void> Function(String url) toggleAudio;
  final bool isPlaying;
  final String currentAudioUrl;
  final Function setState;
  final AudioPlayer audioPlayer;

  const MessageOptions({
    Key? key,
    required this.data,
    required this.document,
    required this.msgEditController,
    required this.receiverUserID,
    required this.chatService,
    required this.reactions,
    required this.hasReactions,
    required this.toggleAudio,
    required this.isPlaying,
    required this.currentAudioUrl,
    required this.setState,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        children: [
          ListTile(
            title: Text(lanNotifier.translate('messageOptions')),
          ),
          if (data['senderId'] == FirebaseAuth.instance.currentUser!.uid)
            ListTile(
              leading: Icon(Icons.delete),
              title: Text(lanNotifier.translate('delete')),
              onTap: () {
                print('Deleting message with ID: ${document.id}');
                chatService.deleteMsg(context, receiverUserID, document.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    lanNotifier.translate('messageDeleted'),
                    style: TextStyle(color: Colors.red),
                  ),
                  action: SnackBarAction(
                    label: lanNotifier.translate('undo'),
                    onPressed: () {
                      print('Undoing message deletion');
                      chatService.undoMsgDelete(receiverUserID, document.id, data['message']);
                    },
                  ),
                ));
              },
            ),
          if (data['senderId'] == FirebaseAuth.instance.currentUser!.uid && data['type'] != 'image' && data['type'] != 'document' && data['type'] != 'audio')
            ListTile(
              leading: Icon(Icons.edit),
              title: Text(lanNotifier.translate('edit')),
              onTap: () {
                msgEditController.text = data['message'];
                Navigator.pop(context); // Close the bottom sheet to show the dialog
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(lanNotifier.translate('editMsg')),
                        content: TextField(
                          controller: msgEditController,
                          decoration: InputDecoration(
                            hintText: lanNotifier.translate('newMsg'),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(lanNotifier.translate('cancel'))),
                          TextButton(
                              onPressed: () async {
                                print('Updating message with new message: ${msgEditController.text}');
                                bool updateSuccessful = await chatService.updateMsg(receiverUserID, document.id, msgEditController.text);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                    updateSuccessful ? lanNotifier.translate('messageUpdated') : lanNotifier.translate('messageAlreadyUpdated'),
                                    style: TextStyle(color: updateSuccessful ? Colors.green : Colors.deepOrange),
                                  ),
                                ));
                              },
                              child: Text(lanNotifier.translate('update'))),
                        ],
                      );
                    });
              },
            ),
          ListTile(
            leading: Icon(Icons.emoji_emotions),
            title: Text(lanNotifier.translate('react')),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet before opening another dialog
              await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(lanNotifier.translate('reactToMessage')),
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8.0, // Horizontal space between chips.
                            children: reactions.map((reaction) => SimpleDialogOption(
                              onPressed: () async {
                                print('Reacting to message with ${reaction.emoji}');
                                await chatService.reactToMsg(receiverUserID, document.id, reaction.id, reaction.emoji);
                                Navigator.pop(context); // Close the dialog after reacting
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Use min size of Row.
                                children: [
                                  Text(reaction.emoji),
                                ],
                              ),
                            )).toList(),
                          ),
                          if (hasReactions(data)) Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton(
                              onPressed: () async {
                                print('Removing reaction to message');
                                await chatService.removeReaction(receiverUserID, document.id);
                                Navigator.pop(context); // Close the dialog after removing a reaction
                              },
                              child: Text(lanNotifier.translate('removeReaction')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (data['senderId'] != FirebaseAuth.instance.currentUser!.uid)
            ListTile(
              leading: Icon(Icons.report),
              title: Text(lanNotifier.translate('report')),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet before opening another dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(lanNotifier.translate('reportMessage')),
                    content: Text(lanNotifier.translate('reportMsgContent')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(lanNotifier.translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          print('Reporting user with ID: $receiverUserID');
                          chatService.reportUser(document.id, receiverUserID);
                          Navigator.pop(context); // Close the dialog after reporting

                          //show snackbar after reporting
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lanNotifier.translate('msgReported')),
                            ),
                          );
                        },
                        child: Text(lanNotifier.translate('report')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text(lanNotifier.translate('cancel')),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}