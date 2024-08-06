import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedContacts extends StatelessWidget {
  BlockedContacts({super.key});

  //chat and auth service
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //unblock box
  void _showUnblockBox(BuildContext context, String userId) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lanNotifier.translate('unBlockContact')),
          content: Text(lanNotifier.translate('unblockMsg')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(lanNotifier.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                _chatService.unblockUser(userId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lanNotifier.translate('contactUnblocked')),
                  ),
                );
              },
              child: Text(lanNotifier.translate('unblock')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;

    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lanNotifier.translate('blockedContacts')),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getBlockedUsers(userId),
        builder: (context, snapshot) {

          //errors..
          if (snapshot.hasError) {
            return Center(
              child: Text(lanNotifier.translate('error')),
            );
          }

          //loading..
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          //no blocked users
          if (blockedUsers.isEmpty) {
            return Center(
              child: Text(lanNotifier.translate('noBlockedContacts')),
            );
          }

          //load complete
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final contact = blockedUsers[index];
              return ListTile(
                title: Text(contact['name']),
                subtitle: Text(contact['email']),
                trailing: IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () {
                    _showUnblockBox(context, contact['uid']);
                  },
                ),
              );
            }
          );
        },
      ),
    );
  }
}
