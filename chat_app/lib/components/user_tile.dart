import 'package:chat_app/language/locale_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class UserTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<String> Function(String uid) getImageUrl;
  final Stream<QuerySnapshot> Function(String currentUserId, String contactId) getLastMsg;
  final LanguageNotifier lanNotifier;
  final ValueNotifier<Set<String>> selectedContactIds;

  UserTile({
    required this.data,
    required this.onTap,
    required this.onLongPress,
    required this.getImageUrl,
    required this.getLastMsg,
    required this.lanNotifier,
    required this.selectedContactIds,
  });

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String formatDate(Timestamp timestamp, BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateFormat timeFormatter = DateFormat('h:mm a');
    DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return timeFormatter.format(date);
    } else if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return '${lanNotifier.translate('yesterday')} ${timeFormatter.format(date)}';
    } else {
      return dateFormatter.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedContactIds,
      builder: (context, selectedContacts, _) {
        bool isSelected = selectedContacts.contains(data['uid']);

        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10.0),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 0, 0, 1).withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              ListTile(
                leading: Container(
                  width: 60,
                  child: FutureBuilder<String>(
                    future: getImageUrl(data['uid']),
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasError) {
                        return const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.done) {
                        String imageUrl = snapshot.data!;
                        if (imageUrl.isNotEmpty) {
                          return CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(imageUrl),
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading image: $exception');
                            },
                          );
                        } else {
                          return const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.person),
                          );
                        }
                      }

                      return const CircleAvatar(
                        radius: 30,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                title: Text(data['name'] ?? 'No name'),
                subtitle: StreamBuilder(
                  stream: getLastMsg(_auth.currentUser!.uid, data['uid']),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Text(lanNotifier.translate('loading'));
                      default:
                        if (snapshot.data!.docs.isEmpty) {
                          return Text(lanNotifier.translate('noMessageYet'));
                        } else {
                          final latestMsg = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                          Timestamp timestamp = latestMsg['timestamp'] as Timestamp;
                          String formattedTimestamp = formatDate(timestamp, context);
                          String? messageType = latestMsg['type'] as String?;
                          String message;

                          switch (messageType) {
                            case 'image':
                              message = lanNotifier.translate('imageMsg');
                              break;
                            case 'document':
                              message = lanNotifier.translate('documentMsg');
                              break;
                            case 'audio':
                              message = lanNotifier.translate('audioMsg');
                              break;
                            default:
                              message = latestMsg['message'];
                              break;
                          }

                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  message,
                                  style: DefaultTextStyle.of(context).style,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                formattedTimestamp,
                                style: DefaultTextStyle.of(context).style,
                              ),
                            ],
                          );
                        }
                    }
                  },
                ),
                onTap: onTap,
                onLongPress: () {
                  // Toggle selection
                  //difference is used to remove the element from the set, union is used to add the element to the set
                  final isCurrentlySelected = selectedContacts.contains(data['uid']);
                  selectedContactIds.value = isCurrentlySelected
                      ? selectedContacts.difference({data['uid']})
                      : selectedContacts.union({data['uid']});
                },
              ),
              if (data['unreadMessages'] != null && data['unreadMessages'] > 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      data['unreadMessages'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}


