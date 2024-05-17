// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/components/chat_bubble.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/components/typing_indicator.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/model/message.dart';
import 'package:chat_app/pages/profile_details_page.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
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
  final TextEditingController _msgReplyController = TextEditingController();
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

    //call a method from chat service to reset the unread messages field for the current user
    _chatService.readMsg(widget.receiverUserID);

    //add listener to focus node
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        // then the amount of remaining space will be calculated
        // then scroll down
        Future.delayed(const Duration(milliseconds: 600), () => scrollDown());
      }
    });

    // wait a bit for listview to be built, then scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () => scrollDown());
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.extentTotal + 1000.0,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMsg(String message) async {
    //check if the _msgController is empty
    if (_msgController.text.isEmpty) {
      print('Message controller is empty. No message to send.');
      return;
    }

    //only send message if there is something to send
    if (_msgController.text.isNotEmpty) {
      await _chatService.sendMsg(
          widget.receiverUserID, _msgController.text, MessageType.text);

      // After sending the message, set 'typing' to false
      FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'typing': false,
      });

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
    // final lanNotifier = Provider.of<LanguageNotifier>(context);
    await _chatService.deleteMsg(context, widget.receiverUserID, msg);
  }

  //format the date to show the time if the message was sent today or yesterday, otherwise show the date
  String formatDate(Timestamp timestamp) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateFormat timeFormatter = DateFormat('HH:mm a');
    DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${lanNotifier.translate('today')} ${timeFormatter.format(date)}';
    } else if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return '${lanNotifier.translate('yesterday')} ${timeFormatter.format(date)}';
    } else {
      return '${dateFormatter.format(date)} ${timeFormatter.format(date)}';
    }
  }

  ValueNotifier<List<XFile>> pickedImagesNotifier =
      ValueNotifier<List<XFile>>([]);
  ValueNotifier<Map<String, bool>> sendingStatesNotifier =
      ValueNotifier<Map<String, bool>>({});
  ValueNotifier<bool> isImageReceivedNotifier = ValueNotifier<bool>(false);
  bool isImageSending = false;

  Future selectImageFile() async {
    print('selectFile: pickedImage: $pickedImagesNotifier');
    final result = await ImagePicker().pickMultiImage(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      imageQuality: 80,
    );
    for (var image in result) {
      pickedImagesNotifier.value.add(XFile(image.path));
      sendingStatesNotifier.value[image.path] = false;
    }
    isImageReceivedNotifier.value = true;
    }

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              //status indicator if user is online or offline
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.receiverUserID)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    String status = (data['status'] ?? 'offline').toLowerCase();
                    print('Status: $status');
                    Color statusColor =
                        status == 'online' ? Colors.green : Colors.grey;
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
                            data['name'] ?? lanNotifier.translate('unknown'),
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
                    return Text(lanNotifier.translate('error'));
                  } else {
                    return Text(lanNotifier.translate('loading'));
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
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return StreamBuilder(
      stream:
          _chatService.getMsg(widget.receiverUserID, _auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(lanNotifier.translate('error'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(lanNotifier.translate('loading'));
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
        ? (isDarkMode ? Colors.green.shade600 : Colors.grey.shade600)
        : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300);

    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return GestureDetector(
      onLongPress: () {
  if (data['senderId'] == _auth.currentUser!.uid) {
    //set the text of _msgController to the current message
    _msgEditController.text = data['message'];

    //show a dialog to delete and edit the message
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final lanNotifier =
              Provider.of<LanguageNotifier>(context, listen: false);
          return AlertDialog(
            title: Text(lanNotifier.translate('deleteMsg')),
            content: data['type'] == 'image'
                ? Text(lanNotifier.translate('imageMsg'))
                : Text(data['message']),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(lanNotifier.translate('cancel'))),
              TextButton(
                  onPressed: () {
                    //delete the message calling the deleteMsg method from the chat service
                    _chatService.deleteMsg(
                        context, widget.receiverUserID, document.id);
                    Navigator.pop(context);
                    //show a snackbar to confirm that the message was deleted
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        lanNotifier.translate('messageDeleted'),
                        style: TextStyle(color: Colors.red),
                      ),
                      action: SnackBarAction(
                        label: lanNotifier.translate('undo'),
                        onPressed: () {
                          //undo the message deletion calling the undoMsgDelete method from the chat service
                          _chatService.undoMsgDelete(
                              widget.receiverUserID,
                              document.id,
                              data['message']);
                        },
                      ),
                    ));
                  },
                  child: Text(lanNotifier.translate('delete'))),
              if (data['type'] != 'image') ...[
                TextButton(
                  onPressed: () {
                    //set the text of _msgController to the current message
                    _msgEditController.text = data['message'];

                    //show a dialog to edit the message
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final lanNotifier = Provider.of<LanguageNotifier>(
                              context,
                              listen: false);
                          return AlertDialog(
                            title: Text(lanNotifier.translate('editMsg')),
                            content: TextField(
                              controller: _msgEditController,
                              decoration: InputDecoration(
                                hintText: lanNotifier.translate('newMsg'),
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                      lanNotifier.translate('cancel'))),
                              TextButton(
                                  onPressed: () async {
                                    bool updateSuccessful =
                                        await _chatService.updateMsg(
                                            widget.receiverUserID,
                                            document.id,
                                            _msgEditController.text);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                        updateSuccessful
                                            ? lanNotifier.translate(
                                                'messageUpdated')
                                            : lanNotifier.translate(
                                                'messageAlreadyUpdated'),
                                        style: TextStyle(
                                            color: updateSuccessful
                                                ? Colors.green
                                                : Colors.deepOrange),
                                      ),
                                    ));
                                  },
                                  child: Text(
                                      lanNotifier.translate('update'))),
                            ],
                          );
                        });
                  },
                  child: Text(lanNotifier.translate('edit')),
                )
              ],
            ],
          );
        });
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
              // Text(data['senderEmail']),
              // const SizedBox(height: 5),
              //show the message in a chat bubble
              ChatBubble(
                content: (sendingStatesNotifier.value[data['message']] == true)
                    ? const CircularProgressIndicator()
                    : (data['isDeleted'] ?? false)
                        ? Text(lanNotifier.translate('messageDeleted'))
                        : (data['type'] == 'image'
                            ? GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PhotoView(
                                                imageProvider: NetworkImage(
                                                    data['message']),
                                                minScale: PhotoViewComputedScale
                                                    .contained,
                                              )));
                                },
                                child: Container(
                                  width: 200, // Set your desired width
                                  height: 100, // Set your desired height
                                  child: CachedNetworkImage(
                                    imageUrl: data['message'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => 
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.error,
                                      color: Colors.red
                                    ),
                                  )
                                ),
                              )
                            : Text(data['message'])),
                bubbleColor: bubbleColor,
              ),

              //show the time the message was sent
              Text(
                formatDate(data['timestamp']),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
              //show if the message has been delivered or seen by the user
              if (data['senderId'] == _auth.currentUser!.uid)
                Text(
                  data['isRead'] == true
                      ? lanNotifier.translate('seen')
                      : lanNotifier.translate('delivered'),
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
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    String otherUserID = widget.receiverUserID;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserID)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return const SizedBox.shrink();
                } else if (snapshot.hasData && snapshot.data!.data() != null) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  if (!data.containsKey('typing')) {
                    print('Document does not contain typing field');
                    return const SizedBox.shrink();
                  }
                  bool isTyping = data['typing'] ?? false;
                  print('isTyping: $isTyping');
                  String name = data['name'] ?? '';
                  return isTyping
                      ? Column(
                          children: [
                            Text('$name ${lanNotifier.translate('typing')}'),
                            const SizedBox(height: 15),
                            TypingIndicator(isTyping: isTyping),
                          ],
                        )
                      : const SizedBox.shrink();
                } else {
                  print('Document does not exist or data is null');
                  return const SizedBox.shrink();
                }
              }),
          const SizedBox(height: 15),
          Row(
            children: [
              //text field
              Expanded(
                child: MyTextField(
                  controller: _msgController,
                  hintText: lanNotifier.translate('message'),
                  obscureText: false,
                  isEnabled: true,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({
                        'typing': true,
                      });
                    } else {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({
                        'typing': false,
                      });
                    }
                  },
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () async {
                          final List<XFile> imgs =
                              await ImagePicker().pickMultiImage(
                            imageQuality: 70,
                          );
                          if (imgs.isEmpty) {
                            return;
                          }
                          for (var i in imgs) {
                            pickedImagesNotifier.value.add(i);
                            sendingStatesNotifier.value[i.path] = true;
                            isImageReceivedNotifier.value = true;

                            //send the picked image
                            await _chatService.sendChatImage(
                                otherUserID, File(i.path));
                            //after the image is sent, set the sending state to false
                            sendingStatesNotifier.value[i.path] = false;
                            sendingStatesNotifier.notifyListeners();

                            //scroll down after sending the image
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollDown();
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.attach_file,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final XFile? img = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 70,
                          );
                          if (img != null) {
                            pickedImagesNotifier.value.add(img);
                            sendingStatesNotifier.value[img.path] = true;
                            isImageReceivedNotifier.value = true;

                            //send the picked image
                            await _chatService.sendChatImage(
                                otherUserID, File(img.path));
                            //after the image is sent, set the sending state to false
                            sendingStatesNotifier.value[img.path] = false;
                            sendingStatesNotifier.notifyListeners();

                            //scroll down after sending the image
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollDown();
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              //send button
              IconButton(
                onPressed: () async {
                  String message = '';

                  DocumentSnapshot senderDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .get();

                  String senderName = senderDoc['name'];

                  // If there is a text message, modify the message to include the sender's name
                  if (_msgController.text.isNotEmpty) {
                    message = senderName + ' : ' + _msgController.text;
                  }

                  // If there is a text message, send the message
                  if (_msgController.text.isNotEmpty) {
                    sendMsg(message);

                    String title = 'New Message';

                    // Get the FCM token of the receiver user
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserID)
                        .get();
                    String token = userDoc['token'];

                    // Send the notification
                    LocalNotificationService localNotificationService =
                        LocalNotificationService();
                    localNotificationService.sendNotification(
                        title, message, token);

                    //scroll down after sending the text
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      scrollDown();
                    });
                  } else {
                    print('Message controller is empty. No message to send.');
                  }
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
