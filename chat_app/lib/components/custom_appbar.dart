import 'package:chat_app/language/locale_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearchOpened;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onFriendRequestsPressed;
  final VoidCallback onSearchToggle;
  final ValueNotifier<Set<String>> selectedContactIds;
  final Future<void> Function() onDeleteSelectedContacts;
  final Future<void> Function() onBlockSelectedContacts;

  CustomAppBar({
    required this.isSearchOpened,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFriendRequestsPressed,
    required this.onSearchToggle,
    required this.selectedContactIds,
    required this.onDeleteSelectedContacts,
    required this.onBlockSelectedContacts,
  });

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);

    return AppBar(
      title: Stack(
        children: [
          Row(
            children: [
              AnimatedOpacity(
                opacity: isSearchOpened ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  lanNotifier.translate('birdyMate'),
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 20,
                  ),
                ),
              ),
              Spacer(),
              ValueListenableBuilder<Set<String>>(
                valueListenable: selectedContactIds,
                builder: (context, selectedContactIds, child) {
                  if (selectedContactIds.isEmpty) {
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: onSearchToggle,
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return const Icon(Icons.person);
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

                            return Stack(
                              children: <Widget>[
                                IconButton(
                                  onPressed: onFriendRequestsPressed,
                                  icon: const Icon(Icons.person),
                                ),
                                if (data['friendRequests'] != null && data['friendRequests'] > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
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
                                        data['friendRequests'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: onDeleteSelectedContacts,
                          tooltip: lanNotifier.translate('delete'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.block),
                          onPressed: onBlockSelectedContacts,
                          tooltip: lanNotifier.translate('block'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}





