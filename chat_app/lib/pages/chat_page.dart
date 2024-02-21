import 'package:chat_app/components/chat_bubble.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/components/typing_indicator.dart';
import 'package:chat_app/pages/profile_details_page.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserEmail;
  final String receiverUserID;
  const ChatPage({
    super.key,
    required this.receiverUserName,
    required this.receiverUserEmail,
    required this.receiverUserID,
    // required this.otherUserId,
    // required this.receiverUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _msgEditController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore database = FirebaseFirestore.instance;

  //for textfield focus
  final FocusNode _focusNode = FocusNode();

  //update date
  // Timer? _timer;

  @override
  void initState() {
    super.initState();

    //add listener to focus node
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        // then the amount of remaining space will be calculated
        // then scroll down
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
      }
    });

    // wait a bit for listview to be built, then scroll to bottom
    Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
  }

  @override
  void dispose() {
    // _timer?.cancel();
    _focusNode.dispose();
    _msgController.dispose();
    super.dispose();
  }

  // scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeOut,
      );
  }

  void sendMsg() async {
    //only send message if there is something to send
    if (_msgController.text.isNotEmpty) {
      await _chatService.sendMsg(widget.receiverUserID, _msgController.text);

      // After sending the message, set 'typing' to false
      FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).update(
        {
          'typing': false,
        }
      );

      //clear the text controller after sending the message
      _msgController.clear();
    }
    //scroll down after sending the message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollDown();
    });
  }

  //delete message
  void deleteMsg(String msg) async {
    await _chatService.deleteMsg(widget.receiverUserID, msg);
  }

  //format the date to show the time if the message was sent today or yesterday, otherwise show the date
  String formatDate(Timestamp timestamp) {

    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateFormat timeFormatter = DateFormat('HH:mm a');
    DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today ${timeFormatter.format(date)}';
    } else if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Yesterday ${timeFormatter.format(date)}';
    } else {
      return '${dateFormatter.format(date)} ${timeFormatter.format(date)}';
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
            //status indicator if user is online or offline
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverUserID).snapshots(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                    String status = (data['status'] ?? 'offline').toLowerCase();
                    print('Status: $status'); 
                    Color statusColor = status == 'online' ? Colors.green : Colors.grey;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ProfileDetails(
                              receiverUserEmail: widget.receiverUserEmail,
                              receiverUserID: widget.receiverUserID,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: statusColor,
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const Text('Loading...');
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          //message list
          Expanded(
            child: _buildMessageList(),
          ),
          //user input
          _buildMessageInput(),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

//build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream:
          _chatService.getMsg(widget.receiverUserID, _auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error${snapshot.hasError}}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

//build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    //align the messages to the right if the sender is the current user, otherwise align to the left
    var alignment = (data['senderId'] == _auth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    var bubbleColor = (data['senderId'] == _auth.currentUser!.uid)
        ? (isDarkMode ? Colors.green.shade600 : Colors.grey.shade500)
        : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200);

    return GestureDetector(
      onLongPress: () {
        if (data['senderId'] == _auth.currentUser!.uid) {
          //show a dialog to delete and edit the message
          showDialog(
            context: context, 
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete Message'),
                content: Text(data['message']),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    }, 
                    child: const Text('Cancel')
                  ),
                  TextButton(
                    onPressed: () {
                      //delete the message calling the deleteMsg method from the chat service
                      _chatService.deleteMsg(widget.receiverUserID, document.id);
                      Navigator.pop(context);
                      //show a snackbar to confirm that the message was deleted
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Message deleted',
                            style: TextStyle(
                              color: Colors.red
                            ),
                          ),
                        )
                      );
                    }, 
                    child: const Text('Delete')
                  ),
                  TextButton(
                    onPressed: () {
                      //set the text of _msgController to the current message
                      _msgEditController.text = data['message'];

                      //show a dialog to edit the message
                      showDialog(
                        context: context, 
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Edit Message'),
                            content: TextField(
                              controller: _msgEditController,
                              decoration: const InputDecoration(
                                hintText: 'Enter new message',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  //update the message calling the updateMsg method from the chat service
                                  bool updateSuccessful = await _chatService.updateMsg(widget.receiverUserID, document.id, _msgEditController.text);
                                  Navigator.pop(context);
                                  //show a snackbar to confirm that the message was updated
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        updateSuccessful ? 'Message updated' : 'Message has already been updated',
                                        style: TextStyle(
                                          color: updateSuccessful ? Colors.green : Colors.deepOrange
                                        ),
                                      ),
                                    ),
                                  );
                                }, 
                                child: const Text('Update')
                              ),
                            ],
                          );
                        }
                      );
                    }, 
                    child: const Text('Edit'),
                  )
                ],
              );
            }
          );
        }
      },
      child: Container(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: (data['senderId'] == _auth.currentUser!.uid)
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisAlignment: (data['senderId'] == _auth.currentUser!.uid)
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(data['senderEmail']),
              const SizedBox(height: 5),
              //show the message in a chat bubble
              ChatBubble(msg: data['message'], bubbleColor: bubbleColor),
              //show the time the message was sent
              Text(
                formatDate(data['timestamp']),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  //build message input
  Widget _buildMessageInput() {
    // String otherUserEmail = widget.receiverUserEmail;
    String otherUserID = widget.receiverUserID;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          const SizedBox(height: 15),
          //typing indicator
          StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(otherUserID).snapshots(), 
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              print('StreamBuilder error: ${snapshot.error}');
              return const SizedBox.shrink();
            } else if (snapshot.hasData && snapshot.data!.data() != null) {
              Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
              if (!data.containsKey('typing')) {
                print('Document does not contain typing field');
                return const SizedBox.shrink();
              }
              bool isTyping = data['typing'] ?? false;
              print('isTyping: $isTyping');
              String email = data['email'] ?? '';
              return isTyping ? Column(
                children: [
                  Text('$email is typing...'),
                  const SizedBox(height: 15),
                  TypingIndicator(isTyping: isTyping),
                ],
              ) : const SizedBox.shrink();
            } else {
              print('Document does not exist or data is null');
              return const SizedBox.shrink();
            }
          }
        ),
          const SizedBox(height: 25),
          Row(
            children: [
              //text field
              Expanded(
                  child: MyTextField(
                  controller: _msgController,
                  hintText: 'Type a message',
                  obscureText: false,
                  isEnabled: true,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).update(
                        {
                          'typing': true,
                        }
                      );
                    } else {
                      FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).update(
                        {
                          'typing': false,
                        }
                      );
                    }
                  }
                ),
              ),
              const SizedBox(width: 15),
              //send button
              IconButton(
                onPressed: () async {
                  sendMsg(); // Existing function to send the message

                  String title = 'New Message';
                  String message = _msgController.text;

                  // Get the FCM token of the receiver user
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserID).get();
                  String token = userDoc['token'];

                  // Send the notification
                  LocalNotificationService localNotificationService = LocalNotificationService();
                  localNotificationService.sendNotification(title, message, token);
                },
                icon: const Icon(
                  Icons.send,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
