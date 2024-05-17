// import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotification extends StatefulWidget {

  const PushNotification({
    super.key,
  });

  @override
  State<PushNotification> createState() => _PushNotificationState();
}

class _PushNotificationState extends State<PushNotification> {
  // final ChatService _chatService = ChatService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  //create a list to store the messages
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.getToken().then((String? token) {
      assert(token != null);
      print('Push Messaging token: $token');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        //add the message to the list
        setState((){
          _messages.add({
            'message': notification.body ?? 'No message',
            'timestamp': DateTime.now().toString(),
          });
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });
  }

  // void getMsg(String message) async {
  //   await _chatService.getMsg(widget.senderUserID, widget.receiverUserID);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Push Notifications'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_messages[index]['message']),
                        subtitle: Text(_messages[index]['timestamp']),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
