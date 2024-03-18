// ignore_for_file: use_build_context_synchronously, sort_child_properties_last


import 'package:chat_app/components/side_bar.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/pages/complete_profile.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//http
// import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  // final String receiverUserID;
  // final String receiverUserEmail;
  const HomePage({
    super.key,
    // required this.receiverUserID,
    // required this.receiverUserEmail,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  //show logged in user's email
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessage.listen((event) { 
      LocalNotificationService.display(event);
    });

    LocalNotificationService.storeToken();

    WidgetsBinding.instance.addPostFrameCallback((_) async { 
      await user?.reload();
      if (user != null) {
        //update the emailVerified field in the database whether the email is verified or not
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
          'emailVerified': user?.emailVerified,
        });

        //check if the user has completed their profile
        Future.microtask(() => checkUserProfile(user!));
      }
    });
  }

  final CollectionReference _user =
      FirebaseFirestore.instance.collection('users');
  
  bool navigating = false;

  checkUserProfile(User user) async {
    final DocumentSnapshot userDoc = await _user.doc(user.uid).get();

    if (userDoc.exists) {
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['name'] == null && !navigating) {
        // ignore: unnecessary_null_comparison
        // print('context is ${context != null ? '' : 'not '}valid');
        navigating = true;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => const CompleteProfile()
          ),
        );
      }
    }
  }

  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //sign out
  void signOut() async {
    //get auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    authService.signOut();
  }

  void approveRequest(String senderId, String senderEmail, String senderName) async {
    String name = senderName;

    // accept contact request
    await FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('contacts')
      .doc(senderId)
      .set({
        'name': name,
        'email': senderEmail,
        'uid': senderId
      });
      print('name: $name, email: $senderEmail, uid: $senderId');
      print('Sender ID: $senderId');

      final DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

        //get the name of the current user
        String username = currentUserDoc.get('name') ?? 'No name';

      //add the current user to the sender's contacts
      await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .collection('contacts')
        .doc(_auth.currentUser!.uid)
        .set({
          'name': username,
          'email': _auth.currentUser!.email,
          'uid': _auth.currentUser!.uid
        });
        print('name: $name, email: $senderEmail, uid: $senderId');
        print('Current user ID: ${_auth.currentUser!.uid}');

        //clear the contact request
        await deleteRequest(senderId);
  }

  //delete contact request
  deleteRequest(String senderId) async {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('contactRequests')
      .doc(senderId)
      .delete();
      print('request deleted');
  }

  //delete contact
  deleteContact(String contactId) async {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('contacts')
      .doc(contactId)
      .delete();
      print('contact deleted');
  }

  List<DocumentSnapshot> searchResults = [];

  bool noResFound = false;

  //search for the contact
  search(String query) async {

    print('Searching...');
    final QuerySnapshot res = await FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('contacts')
      .orderBy('name')
      .startAt([query])
      .endAt([query + '\uf8ff'])
      .get();
      print('Search results: $res');

      if (res.docs.isEmpty) {
        setState(() {
          noResFound = true;
          searchResults = [];
        });
      } else {
        setState(() {
          noResFound = false;
          searchResults = res.docs;
        });
        print('Search results: $searchResults');

        //iterate over the documents in the query results and print the data
        res.docs.forEach((doc) {
          print(doc.data());
        });
      }
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  bool _isSearchOpened = false;

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Stack(
          children: [
            Row(
              children: [
                AnimatedOpacity(
                  //opacity is 0 when the search bar is opened and 1 when it is closed
                  opacity: _isSearchOpened ? 0 : 1, 
                  duration: const Duration(milliseconds: 300),
                  child: Text(lanNotifier.translate('contacts')),
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  // onPressed: _handleSearchBar,
                  onPressed: () {
                    setState(() {
                      _isSearchOpened = !_isSearchOpened;
                    });
                  }, 
                ),
              ],
            ),
            Center(
              child: AnimatedContainer(
                width: _isSearchOpened ? 200 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,

                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: lanNotifier.translate('search'),
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                    ),
                  ),
                  onChanged: (value) {
                    _searchNotifier.value = value;
                    search(value);
                  },
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: const MenuSideBar(),
      body: Column(
        children: [
          // _buildAddUserBar(),
          Flexible(
            flex: 1,
            child: _buildContactRequestList()
          ),
          Expanded(
            flex: 2,
            child: buildBody(),
          ),
        ],
      ),
      floatingActionButton: _buildAddUserBar(),
    );
  }

  

  Widget buildBody() {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return Column(
      children: [
        StreamBuilder(
          stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('contacts')
            .orderBy('name')
            .snapshots(), 
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text(lanNotifier.translate('error'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(lanNotifier.translate('loading'));
            }

            final docs = searchResults.isNotEmpty ? searchResults : snapshot.data!.docs;

            if (noResFound) {
              return Expanded(
                child: Center(
                  child: Text(lanNotifier.translate('noResFound')),
                ),
              );
            } else {
              return Expanded(
                child: ListView(
                  children: docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 0, 0, 1).withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      ),
                      child: ListTile(
                        // leading: Text(data['name'] ?? 'Unknown'),
                        title: Text(data['name'] ?? 'No name'),
                        // trailing: CircleAvatar(
                        //   backgroundColor: statusColor,
                        //   radius: 10.0,
                        // ),
                        onTap: () {
                          print('Name: ${data['name']}, Email: ${data['email']}, UID: ${data['uid']}');
                          if (data['name'] != null && data['email'] != null && data['uid'] != null) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  receiverUserName: data['name'],
                                  receiverUserEmail: data['email'],
                                  receiverUserID: data['uid'],
                                ),
                              ),
                            );
                            setState(() {
                              _searchController.clear();
                              _searchNotifier.value = '';
                              searchResults = [];
                              _isSearchOpened = false;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lanNotifier.translate('error')),
                              ),
                            );
                          }
                        },
                        onLongPress: () async {
                          await showDialog(
                            context: context, 
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(lanNotifier.translate('deleteContact')),
                                content: Text(lanNotifier.translate('confirmDeleteContact')),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }, 
                                    child: Text(lanNotifier.translate('cancel'))
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteContact(document.id);
                                      Navigator.pop(context);
                                    }, 
                                    child: Text(lanNotifier.translate('delete'))
                                  ),
                                ],
                              );
                            }
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          }
        )
      ],
    );
  }

  //contact request list
  Widget _buildContactRequestList() {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('contactRequests')
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(lanNotifier.translate('error')); 
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(lanNotifier.translate('loading'));
        }

        return ListView(
          children: snapshot.data!.docs.map<Widget>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Request data: $data');
            final name = data.containsKey('name') && data['name'] != null ? data['name'] : 'No name';
            final email = data.containsKey('email') && data['email'] != null ? data['email'] : 'No email';
            return ListTile(
              title: Text(email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => approveRequest(doc.id, email, name),
                    icon: const Icon(Icons.check)
                  ),
                  IconButton(
                    onPressed: () => deleteRequest(doc.id), 
                    icon: const Icon(Icons.close)
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildAddUserBar() {
  final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
  return FloatingActionButton(
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(lanNotifier.translate('enterEmail')),
            content: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: lanNotifier.translate('email'),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  lanNotifier.translate('send'),
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
                onPressed: () async {
                  String email = _emailController.text;
                  bool userAdded = await _addUser();

                  //get the FCM token of the user with the provided email
                  // DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(email).get('notificationToken' as GetOptions?);
                  // String token = userDoc['notificationToken'];

                  // sendNotification('Friend Request', token);
                  Navigator.of(context).pop();

                  if (userAdded) {
                    //Show a snackbar with the success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lanNotifier.translate('request') + ' $email',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
    child: const Icon(
      Icons.person_add,
    ),
    backgroundColor: Theme.of(context).colorScheme.background,
    foregroundColor: Theme.of(context).colorScheme.primary,
    elevation: 5.0,
    highlightElevation: 10.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
    )
  );
}

  Future<bool> _addUser() async {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    final String email = _emailController.text;

    //check if the entered email is the same as the current user's email
    if (email == _auth.currentUser!.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lanNotifier.translate('cannotAddSelf')),
        ),
      );
      return false;
    }

    //Search for a user with the entered email
    final QuerySnapshot res = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .get();
    final List<DocumentSnapshot> documents = res.docs;
    if (documents.length == 1) {

      final String targetUserId = documents[0].id;

      //check if the user is already in the current user's contacts
      final DocumentSnapshot contactDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('contacts')
        .doc(targetUserId)
        .get();
      
      if (contactDoc.exists) {
        //if the user is already in the current user's contacts, display a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lanNotifier.translate('userAlreadyExists')),
          ),
        );

        //return false to indicate that the user was not added
        return false;
      }

      final DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

        //get the name of the current user
        String name = currentUserDoc.get('name') ?? 'No name';
        String uid = currentUserDoc.get('uid') ?? 'No uid';

      //If a user with the entered email exist, add them to the current user's contacts
      await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('contactRequests')
        .doc(_auth.currentUser!.uid)
        .set({
          'name': name,
          'email': _auth.currentUser!.email,
          'uid': uid,
        });
        print('name: $name, email: ${_auth.currentUser!.email}, uid: ${_auth.currentUser!.uid}');
        print('Request sent to $email');
      //Clear the text field
      _emailController.clear();

      //Return true to indicate that the user was added successfully
      return true;
    } else {
      //If a user with the entered email does not exist, display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lanNotifier.translate('enteredEmail')),
        ),
      );

      //Return false to indicate that the user was not added
      return false;
    }
  }
}